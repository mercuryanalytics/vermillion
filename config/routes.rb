Vermillion::Engine.routes.draw do
  resources :tasks, except: %i(new edit)
end
=begin
Routes for Vermillion::Engine:
 tasks GET    /tasks(.:format)     vermillion/tasks#index
       POST   /tasks(.:format)     vermillion/tasks#create
  task GET    /tasks/:id(.:format) vermillion/tasks#show
       PATCH  /tasks/:id(.:format) vermillion/tasks#update
       PUT    /tasks/:id(.:format) vermillion/tasks#update
       DELETE /tasks/:id(.:format) vermillion/tasks#destroy
=end
