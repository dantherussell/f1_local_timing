class WeekendsController < ApplicationController
  before_action :set_season
  before_action :authenticate, only: %i[destroy edit new create update]

  def show
    @weekend = @season.weekends.find(params[:id])
    @local_events = @weekend.events.order(:start_time).group_by { |e| e.start_time.to_date }
    @track_events = @weekend.events.order(:start_time).group_by(&:date)
  end

  def print
    @weekend = @season.weekends.find(params[:id])
    @track_events = @weekend.events.order(:start_time).group_by(&:date)
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
    params.require(:weekend).permit(:gp_title, :location, :timespan, :local_timezone, :local_time_offset, :race_number, :season_id)
  end
end
