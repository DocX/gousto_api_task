defmodule GoustoApiTask.Recipe do
  use GoustoApiTask.Web, :model

  defstruct id: nil, title: "Recipe", slug: "recipe", recipe_cuisine: "cuisine"

end
