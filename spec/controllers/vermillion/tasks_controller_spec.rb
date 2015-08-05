require 'rails_helper'

module Vermillion
  RSpec.describe TasksController, type: :controller do
    routes { Engine.routes }

    describe "POST #create" do
      context "with valid attributes" do
        it "creates a task" do
          expect {
            post :create, task: FactoryGirl.attributes_for(:vermillion_task)
          }.to change(Task, :count).by(1)
        end

        it "responds with :accepted" do
          post :create, task: FactoryGirl.attributes_for(:vermillion_task)
          expect(response).to have_http_status(:accepted)
        end

        it "includes a Location header with the url of the task" do
          post :create, task: FactoryGirl.attributes_for(:vermillion_task)
          expect(response.headers['Location']).to start_with("http://test.host/vermillion/tasks/")
        end
      end

      context "with invalid attributes" do
        let(:bad_parameters) { { description: { height: 20, width: 30 }} }
        it "does not create a task" do
          expect {
            post :create, task: bad_parameters
          }.not_to change(Task, :count)
        end

        it "responds with :not_acceptable" do
          post :create, task: bad_parameters
          expect(response).to have_http_status(:not_acceptable)
        end

        it "does not include a location header" do
          post :create, task: bad_parameters
          expect(response.headers['Location']).to be_nil
        end

        it "includes a useful error message" do
          post :create, task: bad_parameters
          expect(response.headers['Content-Type'].split(/;/).first).to eq 'application/json'
          expect(JSON.parse(response.body)).to eq("message" => "Validation failed", "errors" => { "definition" => ["can't be blank"] })
        end
      end
    end

    describe "GET #index" do
      before do
        create(:vermillion_task)
        create(:vermillion_task)
      end

      it "populates an array of tasks" do
        get :index
        expect(assigns(:tasks).size).to eq 2
      end

      it "renders the :index view" do
        get :index
        expect(response).to render_template :index
      end
    end

    describe "GET #show" do
      context "with a valid id" do
        let (:task) { create(:vermillion_task) }

        it "assigns the reqeusted task to @tasks" do
          get :show, id: task.id
          expect(assigns(:task)).to eq task
        end

        it "renders the #show template" do
          get :show, id: task.id
          expect(response).to render_template(:show)
        end
      end

      context "with an expired id" do
        let (:task) { create(:expired_vermillion_task) }

        it "responds with :gone" do
          get :show, id: task.id, format: :json
          expect(response).to have_http_status(:gone)
        end
      end

      context "with an invalid id" do
        it "responds with :not_found on an unknown id" do
          get :show, id: 'something-arbitrary', format: :json
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
