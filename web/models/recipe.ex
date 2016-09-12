defmodule GoustoApiTask.Recipe do
  use GoustoApiTask.Web, :model
  #import GoustoApiTask.Model

  defstruct(
    id: nil,
    created_at: nil,
    updated_at: nil,
    box_type: "",
    title: "",
    slug: nil,
    short_title: "",
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
    recipe_cuisine: "",
    in_your_box: nil,
    gousto_reference: nil
  )


  # VALIDATIONS

  def new_initialization(new) do
    # set initial values
    %{
      new |
      created_at: DateTime.utc_now |> DateTime.to_iso8601,
      updated_at: DateTime.utc_now |> DateTime.to_iso8601,
      slug: case new.slug do nil -> slug(new); x -> x end
    }
  end

  # called by Repo before original is added to repository
  def new_validations(repository, new) do
    [
      {Enum.any?(repository, fn(r) -> r.slug == new.slug end), {:slug, "Already taken"}}
      | common_validations(repository, new)
    ]
  end

  # called by Repo before original is replaced by new in repository
  def update_validations(repository, original, new) do
    [
      {original.slug != new.slug, {:slug, "Cannot be updated"}},
      {original.created_at != new.created_at, {:created_at, "Cannot be updated"}}
      | common_validations(repository, new)
    ]
  end

  # Common validations for create and update
  defp common_validations(repository, record) do
    [
      {String.strip(record.title) == "", {:title, "Cannot be blank"}},
      {String.strip(record.recipe_cuisine) == "", {:recipe_cuisine, "Cannot be blank"}},
      {String.strip(record.slug) == "", {:slug, "Cannot be blank"}}
    ]
  end


  # METHODS

  # Generate new slug for given recipe
  def slug(recipe) do
    slug_from_title(recipe.title)
  end
  def slug_from_title(nil) do
    nil
  end
  def slug_from_title(title) do
    title
    |> String.downcase
    |> String.replace(~r/[^a-z0-9]+/, "-")
  end



  # INTERNAL IMPLEMENTATION
  #TODO extract to module or something

  # merge original Recipe struct with attrs that may contain String based keys
  # returns
  # {:ok, new_record } if all ok
  # {:error, [..]} if some attrs were not recognized with array of errors
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

  def string_keys do
    %__MODULE__{}
    |> Map.keys
    |> List.delete(:__struct__)
    |> Enum.map(fn(k) -> Atom.to_string(k) end)
  end

  # VALIDATIONS AND STORING

  def validate_new(repository, new) do
    # initialize new record values
    new = new_initialization(new)

    # validate
    validate(new_validations(repository, new), new)
  end

  def validate_update(repository, orig, new) do
    validate(update_validations(repository, orig, new), new)
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
end
