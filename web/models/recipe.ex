defmodule GoustoApiTask.Recipe do
  use GoustoApiTask.Web, :model

  defstruct(
    id: nil,
    created_at: nil,
    updated_at: nil,
    box_type: nil,
    title: nil,
    slug: nil,
    short_title: nil,
    marketing_description: nil,
    calories_kcal: nil,
    protein_grams: nil,
    fat_grams: nil,
    carbs_grams: nil,
    bulletpoint1: nil,
    bulletpoint2: nil,
    bulletpoint3: nil,
    recipe_diet_type_id: nil,
    season: nil,
    base: nil,
    protein_source: nil,
    preparation_time_minutes: nil,
    shelf_life_days: nil,
    equipment_needed: nil,
    origin_country: nil,
    recipe_cuisine: nil,
    in_your_box: nil,
    gousto_reference: nil
  )

  # called by Repo before original is added to repository
  def validate_new(repository, new) do
    common = common_validation(repository, new)

    cond do
      elem(common, 1) == :error -> common
      Enum.any?(repository, fn(r) -> r.slug == new.slug end) -> {:error, :slug, "Already taken"}
      true -> {:ok, new}
    end
  end

  # called by Repo before original is replaced by new in repository
  def validate_update(repository, original, new) do
    common = common_validation(repository, new)
    cond do
      elem(common, 1) == :error -> common
      original.slug != new.slug -> {:error, :slug, "Cannot be updated"}
      original.created_at != new.created_at -> {:error, :created_at, "Cannot be updated"}
      true -> {:ok, new}
    end
  end

  defp common_validation(repository, record) do
    cond do
      String.strip(record.title) == "" -> {:error, :title, "Cannot be blank"}
      String.strip(record.recipe_cuisine) == "" -> {:error, :recipe_cuisine, "Cannot be blank"}
      String.strip(record.slug) == "" -> {:error, :slug, "Cannot be blank"}
      true -> {:ok, record}
    end
  end

  # merge original Recipe struct with attrs that may contain String based keys
  def merge(original, attrs) do
    case valid_attrs?(attrs) do
      true -> {:ok, merge_do(original, attrs)}
      false -> {:error, :invalid_attributes}
    end
  end

  defp merge_do(original, attrs) do
    string_keys
    |> Enum.reduce(original, fn(k, acc) ->
      case Map.has_key?(attrs, k) do
        true -> Map.put(acc, String.to_atom(k), attrs[k])
        false -> acc
      end
    end)
  end

  def valid_attrs?(attrs) do
    Map.keys(attrs)
    |> Enum.all?(fn(k) -> Enum.member?(string_keys, k) end)
  end

  defp string_keys do
    %__MODULE__{}
    |> Map.keys
    |> List.delete(:__struct__)
    |> Enum.map(fn(k) -> Atom.to_string(k) end)
  end
end
