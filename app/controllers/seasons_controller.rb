class SeasonsController < ApplicationController
  before_action :authenticate, only: %i[destroy edit new create update auth]

  def index
    @seasons = Season.all
  end

  def show
    @season = Season.find(params[:id])
    @weekends = if @season.weekends.where(race_number: nil).none?
      @season.weekends.order(:race_number)
    else
      @season.weekends
    end
  end

  def new
    @season = Season.new
  end

  def edit
    @season = Season.find(params[:id])
  end

  def create
    @season = Season.new(season_params)
    if @season.save
      redirect_to @season, notice: "Season was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @season = Season.find(params[:id])
    if @season.update(season_params)
      redirect_to @season, notice: "Season was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @season = Season.find(params[:id])
    @season.destroy
    redirect_to seasons_url, notice: "Season was successfully deleted."
  end

  def auth
    redirect_to root_path
  end

  private

  def season_params
    params.require(:season).permit(:name)
  end
end
