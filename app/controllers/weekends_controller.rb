class WeekendsController < ApplicationController
  before_action :set_season
  before_action :set_weekend, only: %i[show print edit update destroy import]
  before_action :authenticate, only: %i[destroy edit new create update import]

  def show
    @days = @weekend.days.includes(:events).order(:date)
    @next_event = @weekend.next_event
    @show_countdown = show_countdown?
  end

  def print
    @days = @weekend.days.includes(:events).order(:date)
    render layout: "print"
  end

  def new
    @weekend = @season.weekends.new
  end

  def edit
  end

  def create
    @weekend = @season.weekends.new(weekend_params)
    if @weekend.save
      redirect_to season_weekend_path(@season, @weekend), notice: "Weekend was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @weekend.update(weekend_params)
      redirect_to season_weekend_path(@season, @weekend), notice: "Weekend was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weekend.destroy
    redirect_to season_path(@season), notice: "Weekend was successfully deleted."
  end

  def import
    return unless request.post?

    url = params[:url]
    if url.blank?
      flash.now[:alert] = "Please provide a URL"
      return
    end

    unless allowed_import_url?(url)
      flash.now[:alert] = "Only formula1.com URLs are supported"
      return
    end

    fetcher_result = F1ScheduleFetcher.new(url).call
    unless fetcher_result.success?
      flash.now[:alert] = fetcher_result.errors.join(", ")
      return
    end

    importer_result = F1ScheduleImporter.new(@weekend, fetcher_result.data).call
    if importer_result.success?
      redirect_to season_weekend_path(@season, @weekend),
                  notice: "Successfully imported #{importer_result.data[:events_created]} events."
    else
      flash.now[:alert] = importer_result.errors.join(", ")
    end
  end

  private

  def set_season
    @season = Season.find(params[:season_id])
  end

  def set_weekend
    @weekend = @season.weekends.find(params[:id])
  end

  def weekend_params
    params.require(:weekend).permit(:gp_title, :location, :first_day, :last_day, :local_timezone, :local_time_offset, :race_number, :season_id)
  end

  def show_countdown?
    return false unless @next_event&.start_datetime

    hours_until = (@next_event.start_datetime.to_time - Time.current) / 1.hour
    hours_until <= 24 && hours_until > 0
  end

  def allowed_import_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTPS) && uri.host&.match?(/\A(\w+\.)?formula1\.com\z/)
  rescue URI::InvalidURIError
    false
  end
end
