defmodule GoustoApiTask.Repo do
  # Mimic Ecto interface

  # Insert record to repository based on record type
  def insert(record) do
    GenServer.call(get_type_repo(record.__struct__), {:insert!, record})
  end

  # Insert record to repository based on record type
  def update(record) do
    GenServer.call(get_type_repo(record.__struct__), {:update!, record})
  end

  # Get record by ID
  def get!(type, id) do
    # transform id to integer if it was in string
    {id_int, _} = case id do
      x when is_integer(x) -> {x, ""}
      x when is_bitstring(x) -> Integer.parse(x)
    end

    get_by!(type, "id", id_int)
  end

  # Get record by given field
  def get_by!(type, field_name, value) do
    records = GenServer.call(get_type_repo(type), {:where, %{field_name => value}})
    case records do
      [record | []] -> record
      _ -> nil
    end
  end

  # Get all records
  def all(type) do
    GenServer.call(get_type_repo(type), {:all})
  end

  # Get all records that matches filters
  def all_where(type, filters) do
    GenServer.call(get_type_repo(type), {:where, filters})
  end

  def clear(type) do
    GenServer.cast(get_type_repo(type), {:clear})
  end

  def count(type) do
    GenServer.call(get_type_repo(type), {:count})
  end

  # Get repo name for record type
  defp get_type_repo(type) do
    case type do
      GoustoApiTask.Recipe -> RecipesRepo
      GoustoApiTask.RecipeRating -> RecipeRatingsRepo
    end
  end

end
