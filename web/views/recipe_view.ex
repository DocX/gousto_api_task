defmodule GoustoApiTask.RecipeView do
  use GoustoApiTask.Web, :view

  def render("index.json", %{recipes: recipes}) do
    %{data: render_many(recipes, GoustoApiTask.RecipeView, "recipe.json")}
  end

  def render("show.json", %{recipe: recipe}) do
    %{data: render_one(recipe, GoustoApiTask.RecipeView, "recipe.json")}
  end

  def render("recipe.json", %{recipe: recipe}) do
    %{id: recipe.id,
      title: recipe.title,
      slug: recipe.slug,
      recipe_cuisine: recipe.recipe_cuisine}
  end
end
