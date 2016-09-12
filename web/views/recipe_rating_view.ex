defmodule GoustoApiTask.RecipeRatingView do
  use GoustoApiTask.Web, :view

  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  defp attributes do
    [
      :id,
      :created_at,
      :updated_at,
      :recipe_id,
      :rating
    ]
  end

  def render("index.json-api", %{data: recipes, opts: opts}) do
    %{data: render_many(recipes, GoustoApiTask.RecipeRatingView, "recipe-rating.json-api"),
      links: opts[:page]
    }
  end

  def render("show.json-api", %{data: recipe}) do
    %{data: render_one(recipe, GoustoApiTask.RecipeRatingView, "recipe-rating.json-api")}
  end

  def render("recipe-rating.json-api", %{recipe_rating: recipe}) do
    json_attrs =
      attributes
      |> Enum.map(fn(k) -> {k, Map.get(recipe, k)} end)
      |> Map.new

    %{id: to_string(recipe.id),
      type: "recipe_ratings",
      attributes: json_attrs
    }
  end
end
