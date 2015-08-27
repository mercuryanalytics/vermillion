Vermillion::Engine.routes.draw do
  resources :tasks, except: %i(new edit update)
  get :api, to: 'tasks#api'
end
=begin
Routes for Vermillion::Engine:
 tasks GET    /tasks(.:format)     vermillion/tasks#index
       POST   /tasks(.:format)     vermillion/tasks#create
  task GET    /tasks/:id(.:format) vermillion/tasks#show
       DELETE /tasks/:id(.:format) vermillion/tasks#destroy
   api GET    /api(.:format)       vermillion/tasks#api
=end
