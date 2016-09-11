defmodule GoustoApiTask.RecipeView do
  use GoustoApiTask.Web, :view

  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  def render("index.json", %{recipes: recipes, offset: offset, limit: limit}) do
    # apply pagination
    paginated_recipes =
      recipes
      |> Enum.drop(offset)
      |> Enum.take(limit)

    # render JSON-API response with pagination links
    %{
      data: render_many(paginated_recipes, GoustoApiTask.RecipeView, "recipe.json"),
      links: %{
        first: recipe_url(Endpoint, :index, offset: 0, limit: limit),
        prev: case offset do x when x - limit >= 0 -> recipe_url(Endpoint, :index, offset: x - limit, limit: limit); _ -> nil end,
        next: case offset + limit do x when x < length(recipes) -> recipe_url(Endpoint, :index, offset: x, limit: limit); _ -> nil end,
        last: recipe_url(Endpoint, :index, offset: case length(recipes) - limit do x when x >= 0 -> x; _ -> 0 end, limit: limit)
      }
    }
  end

  def render("show.json", %{recipe: recipe}) do
    %{data: render_one(recipe, GoustoApiTask.RecipeView, "recipe.json")}
  end

  def render("recipe.json", %{recipe: recipe}) do
    %{id: recipe.id,
      type: "recipes",
      attributes: %{
        title: recipe.title,
        slug: recipe.slug,
        recipe_cuisine: recipe.recipe_cuisine}
      }
  end
end
