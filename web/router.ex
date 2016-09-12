defmodule GoustoApiTask.Router do
  use GoustoApiTask.Web, :router

  pipeline :api do
    plug :accepts, ["json-api"]
  end

  scope "/api", GoustoApiTask do
    pipe_through :api
    resources "/recipes", RecipeController, except: [:new, :edit, :delete] do
      resources "/ratings", RecipeRatingController, only: [:create, :index]
    end
  end
end
