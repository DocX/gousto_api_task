defmodule GoustoApiTask.Router do
  use GoustoApiTask.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", GoustoApiTask do
    pipe_through :api
    resources "/recipes", RecipeController, except: [:new, :edit]
  end
end
