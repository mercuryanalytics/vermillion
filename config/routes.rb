Vermillion::Engine.routes.draw do
  resources :tasks, except: %i(new edit update)
end
=begin
Routes for Vermillion::Engine:
 tasks GET    /tasks(.:format)     vermillion/tasks#index
       POST   /tasks(.:format)     vermillion/tasks#create
  task GET    /tasks/:id(.:format) vermillion/tasks#show
       DELETE /tasks/:id(.:format) vermillion/tasks#destroy
=end
