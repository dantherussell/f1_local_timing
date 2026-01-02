class SessionsController < ApplicationController
  before_action :set_series
  before_action :authenticate, except: [:index]

  def index
    @sessions = @series.sessions
    render json: @sessions.select(:id, :name)
  end

  def new
    @session = @series.sessions.new
  end

  def edit
    @session = @series.sessions.find(params[:id])
  end

  def create
    @session = @series.sessions.new(session_params)
    if @session.save
      redirect_to series_path(@series), notice: "Session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @session = @series.sessions.find(params[:id])
    if @session.update(session_params)
      redirect_to series_path(@series), notice: "Session was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @session = @series.sessions.find(params[:id])
    @session.destroy
    redirect_to series_path(@series), notice: "Session was successfully deleted."
  end

  private

  def set_series
    @series = Series.find(params[:series_id])
  end

  def session_params
    params.require(:session).permit(:name)
  end
end
