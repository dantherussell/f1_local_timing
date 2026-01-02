class EventsController < ApplicationController
  before_action :set_season
  before_action :set_weekend
  before_action :authenticate

  def new
    @event = @weekend.events.new
    @series = Series.all
  end

  def edit
    @event = @weekend.events.find(params[:id])
    @series = Series.all
  end

  def create
    @event = @weekend.events.new(event_params)
    if @event.save
      redirect_to season_weekend_path(@season, @weekend), notice: "Event was successfully created."
    else
      @series = Series.all
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @event = @weekend.events.find(params[:id])
    if @event.update(event_params)
      redirect_to season_weekend_path(@season, @weekend), notice: "Event was successfully updated."
    else
      @series = Series.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event = @weekend.events.find(params[:id])
    @event.destroy
    redirect_to season_weekend_path(@season, @weekend), notice: "Event was successfully deleted."
  end

  private

  def set_season
    @season = Season.find(params[:season_id])
  end

  def set_weekend
    @weekend = @season.weekends.find(params[:weekend_id])
  end

  def event_params
    params.require(:event).permit(:racing_class, :name, :start_time_date_field, :start_time_time_field, :local_time_offset, :session_id)
  end
end
