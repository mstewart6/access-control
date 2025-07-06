defmodule AccessControlWeb.Router do
  use AccessControlWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AccessControlWeb do
    pipe_through :api

    # User routes
    resources "/users", UserController, only: [:index, :create]
    get "/users/:id/resources", UserController, :user_resources
    get "/users/with-resource-count", UserController, :resource_count

    # Group routes
    resources "/groups", GroupController
    post "/groups/:id/add-user", GroupController, :add_user
    delete "/groups/:id/user/:user_id", GroupController, :remove_user

    # Resource routes
    resources "/resources", ResourceController, only: [:index, :create]
    get "/resource/:id/access-list", ResourceController, :access_list
    post "/resource/:id/share-group", ResourceController, :share_group
    delete "/resource/:id/group/:group_id", ResourceController, :unshare_group
    post "/resource/:id/share-user", ResourceController, :share_user
    delete "/resource/:id/user/:user_id", ResourceController, :unshare_user
    get "/resources/with-user-count", ResourceController, :user_count
  end
end
