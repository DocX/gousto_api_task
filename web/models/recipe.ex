defmodule GoustoApiTask.Recipe do
  use GoustoApiTask.Web, :model

  defstruct title: "Recipe", slug: "recipe", recipe_cuisine: "cuisine"
end
