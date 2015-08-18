require_dependency "vermillion/application_controller"

module Vermillion
  class TasksController < ApplicationController
    before_action :set_task, except: %i(index create)

    def index
      @tasks = Task.all
    end

    def create
      description = task_params
      name = params[:name]
      @task = Task.new(name: name, description: description)
      if @task.valid?
        @task.save
        @task.perform_later
        render nothing: true, status: :accepted, location: @task
      else
        render json: { message: "Validation failed", errors: @task.errors }, status: :not_acceptable
      end
    end

    def show
      respond_to do |fmt|
        fmt.html do
          raise ActiveRecord::RecordNotFound unless @task
        end
        fmt.json do
          if @task
            if @task.expired?
              render nothing: true, status: :gone
            end
          else
            render nothing: true, status: :not_found
          end
        end
      end
    end

    def destroy
      if @task
        render nothing: true, status: :no_content
      else
        render nothing: true, status: :not_found
      end
    end

    private
    def set_task
      @task = Task.find_by(id: params[:id])
    end

    def task_params
      params.require(:description).permit(
        :url,
        :filename,
        :startTime,
        :endTime,
        :reticle,
        :timeScale,
        :tickScale,
        :yMin,
        :yMax,
        :shellMin, {
        labels: [],
        lines: [
          :label,
          :color, {
          mean: [],
          up: [],
          down: [],
          }]})
    end
  end
end
