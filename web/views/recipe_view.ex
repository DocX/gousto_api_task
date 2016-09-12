defmodule GoustoApiTask.RecipeView do
  use GoustoApiTask.Web, :view

  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  def render("index.json-api", %{data: recipes, opts: opts}) do
    %{data: render_many(recipes, GoustoApiTask.RecipeView, "recipe.json-api"),
      links: opts[:page]
    }
  end

  def render("show.json-api", %{data: recipe}) do
    %{data: render_one(recipe, GoustoApiTask.RecipeView, "recipe.json-api")}
  end

  def render("recipe.json-api", %{recipe: recipe}) do
    %{id: to_string(recipe.id),
      type: "recipes",
      attributes: %{
        title: recipe.title,
        slug: recipe.slug,
        recipe_cuisine: recipe.recipe_cuisine
      }
    }
  end
end
