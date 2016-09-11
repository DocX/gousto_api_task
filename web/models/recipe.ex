defmodule GoustoApiTask.Recipe do
  use GoustoApiTask.Web, :model

  defstruct id: nil, title: nil, slug: nil, recipe_cuisine: nil

  # merge original Recipe struct with attrs that may contain String based keys
  def merge(original, attrs) do
    original
    |> Map.keys
    |> List.delete(:__struct__)
    |> Enum.map(fn(k) -> Atom.to_string(k) end)
    |> Enum.reduce(original, fn(k, acc) ->
      case Map.has_key?(attrs, k) do
        true -> Map.put(acc, String.to_atom(k), attrs[k])
        false -> acc
      end
    end)
  end
end
