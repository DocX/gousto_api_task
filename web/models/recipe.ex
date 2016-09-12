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
    # set initial values
    new = %{
      new |
      created_at: DateTime.utc_now |> DateTime.to_iso8601,
      updated_at: DateTime.utc_now |> DateTime.to_iso8601,
      slug: case new.slug do nil -> slug(new.title); x -> x end
    }

    # validate new record
    [
      {Enum.any?(repository, fn(r) -> r.slug == new.slug end), {:slug, "Already taken"}}
      | common_validations(repository, new)
    ]
    |> validate(new)
  end

  # called by Repo before original is replaced by new in repository
  def validate_update(repository, original, new) do
    [
      {original.slug != new.slug, {:slug, "Cannot be updated"}},
      {original.created_at != new.created_at, {:created_at, "Cannot be updated"}} |
      common_validations(repository, new)
    ]
    |> validate(new)
  end

  defp common_validations(repository, record) do
    [
      {String.strip(record.title) == "", {:title, "Cannot be blank"}},
      {String.strip(record.recipe_cuisine) == "", {:recipe_cuisine, "Cannot be blank"}},
      {String.strip(record.slug) == "", {:slug, "Cannot be blank"}}
    ]
  end

  # collapse validations to validate result
  defp validate(validations, record) do
    errors = validations
      |> Enum.filter(fn({v, _}) -> v end)
      |> Enum.map(fn({_, e}) -> e end)

    case errors do
      [] -> {:ok, record}
      x -> {:error, x}
    end
  end

  # Generate new slug for given recipe
  def slug(recipe) do
    recipe.title
    |> String.downcase
    |> String.replace(~r/[^a-z0-9]+/, "-")
  end

  # merge original Recipe struct with attrs that may contain String based keys
  def merge(original, attrs) do
    case invalid_attributes(attrs) do
      [] -> {:ok, merge_do(original, attrs)}
      invalid -> {:error, Enum.map(invalid, fn(k) -> {k, "Unrecognized attribute"} end)}
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

  def invalid_attributes(attrs) do
    Map.keys(attrs)
    |> Enum.filter(fn(k) -> !Enum.member?(string_keys, k) end)
  end

  defp string_keys do
    %__MODULE__{}
    |> Map.keys
    |> List.delete(:__struct__)
    |> Enum.map(fn(k) -> Atom.to_string(k) end)
  end
end
