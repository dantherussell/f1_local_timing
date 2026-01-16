class DaysController < ApplicationController
  before_action :set_season
  before_action :set_weekend
  before_action :set_day
  before_action :authenticate

  def edit
  end

  def update
    if @day.update(day_params)
      redirect_to season_weekend_path(@season, @weekend), notice: "Day was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @day.destroy
    redirect_to season_weekend_path(@season, @weekend), notice: "Day was successfully deleted."
  end

  private

  def set_season
    @season = Season.find(params[:season_id])
  end

  def set_weekend
    @weekend = @season.weekends.find(params[:weekend_id])
  end

  def set_day
    @day = @weekend.days.find(params[:id])
  end

  def day_params
    params.require(:day).permit(:local_time_offset)
  end
end
