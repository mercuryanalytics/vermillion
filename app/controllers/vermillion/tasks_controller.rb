require_dependency "vermillion/application_controller"

module Vermillion
  class TasksController < ApplicationController
    before_action :set_task, except: %i(index create)

    def api
      respond_to do |fmt|
        fmt.js { redirect_to ActionController::Base.helpers.asset_path('vermillion/application.js'), status: :temporary_redirect }
      end
    end

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
        head :accepted, location: @task
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
      params.require(:name)
      params.require(:description)
    end
  end
end
