defmodule GoustoApiTask.RecipeRating do
  use GoustoApiTask.Web, :model

  alias GoustoApiTask.Repo
  alias GoustoApiTask.Recipe

  defstruct(
    id: nil,
    created_at: nil,
    updated_at: nil,
    recipe_id: nil,
    rating: nil
  )


  # VALIDATIONS

  def new_initialization(new) do
    # set initial values
    %{
      new |
      created_at: DateTime.utc_now |> DateTime.to_iso8601,
      updated_at: DateTime.utc_now |> DateTime.to_iso8601,
      rating: case new.rating do
        x when is_binary(x) -> Integer.parse(x) |> elem(0)
        x when is_integer(x) -> x
        _ -> nil
      end
    }
  end

  # called by Repo before original is added to repository
  def new_validations(repository, new) do
    [
      {Repo.get!(Recipe, new.recipe_id) == nil, {:recipe_id, "Recipe with given ID doesn't exist"}}
      | common_validations(repository, new)
    ]
  end

  # called by Repo before original is replaced by new in repository
  def update_validations(repository, original, new) do
    common_validations(repository, new)
  end

  # Common validations for create and update
  defp common_validations(repository, record) do
    [
      {record.rating < 1 || record.rating > 5, {:rating, "Rating have to be integer number between 1 and 5 inclusive"}}
    ]
  end


  # METHODS

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
