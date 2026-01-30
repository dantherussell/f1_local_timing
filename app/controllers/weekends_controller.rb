class WeekendsController < ApplicationController
  before_action :set_season
  before_action :authenticate, only: %i[destroy edit new create update]

  def show
    @weekend = @season.weekends.find(params[:id])
    @days = @weekend.days.includes(:events).order(:date)
    @next_event = @weekend.next_event
    @show_countdown = show_countdown?
  end

  def print
    @weekend = @season.weekends.find(params[:id])
    @days = @weekend.days.includes(:events).order(:date)
    render layout: "print"
  end

  def new
    @weekend = @season.weekends.new
  end

  def edit
    @weekend = @season.weekends.find(params[:id])
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
    @weekend = @season.weekends.find(params[:id])
    if @weekend.update(weekend_params)
      redirect_to season_weekend_path(@season, @weekend), notice: "Weekend was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weekend = @season.weekends.find(params[:id])
    @weekend.destroy
    redirect_to season_path(@season), notice: "Weekend was successfully deleted."
  end

  private

  def set_season
    @season = Season.find(params[:season_id])
  end

  def weekend_params
    params.require(:weekend).permit(:gp_title, :location, :first_day, :last_day, :local_timezone, :local_time_offset, :race_number, :season_id)
  end

  def show_countdown?
    return false unless @next_event&.start_datetime

    hours_until = (@next_event.start_datetime.to_time - Time.current) / 1.hour
    hours_until <= 24 && hours_until > 0
  end
end
