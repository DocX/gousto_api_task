defmodule GoustoApiTask.RecipeView do
  use GoustoApiTask.Web, :view

  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  defp attributes do
    [
      :id,
      :created_at,
      :updated_at,
      :box_type,
      :title,
      :slug,
      :short_title,
      :marketing_description,
      :calories_kcal,
      :protein_grams,
      :fat_grams,
      :carbs_grams,
      :bulletpoint1,
      :bulletpoint2,
      :bulletpoint3,
      :recipe_diet_type_id,
      :season,
      :base,
      :protein_source,
      :preparation_time_minutes,
      :shelf_life_days,
      :equipment_needed,
      :origin_country,
      :recipe_cuisine,
      :in_your_box,
      :gousto_reference
    ]
  end

  def render("index.json-api", %{data: recipes, opts: opts}) do
    %{data: render_many(recipes, GoustoApiTask.RecipeView, "recipe.json-api"),
      links: opts[:page]
    }
  end

  def render("show.json-api", %{data: recipe}) do
    %{data: render_one(recipe, GoustoApiTask.RecipeView, "recipe.json-api")}
  end

  def render("recipe.json-api", %{recipe: recipe}) do
    json_attrs =
      attributes
      |> Enum.map(fn(k) -> {k, Map.get(recipe, k)} end)
      |> Map.new

    %{id: to_string(recipe.id),
      type: "recipes",
      attributes: json_attrs
    }
  end
end
