class SeriesController < ApplicationController
  before_action :authenticate

  def index
    @all_series = Series.all
  end

  def show
    @series = Series.find(params[:id])
    @sessions = @series.sessions
  end

  def new
    @series = Series.new
  end

  def edit
    @series = Series.find(params[:id])
  end

  def create
    @series = Series.new(series_params)
    if @series.save
      redirect_to series_index_path, notice: "Series was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @series = Series.find(params[:id])
    if @series.update(series_params)
      redirect_to @series, notice: "Series was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @series = Series.find(params[:id])
    @series.destroy
    redirect_to series_index_path, notice: "Series was successfully deleted."
  end

  private

  def series_params
    params.require(:series).permit(:name)
  end
end
