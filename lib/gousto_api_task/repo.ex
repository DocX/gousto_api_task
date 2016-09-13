defmodule GoustoApiTask.Repo do
  use GenServer

  def start_link(state \\ [], opts \\ []) do
    state = case state do
      nil -> new_repo
      x -> x
    end
    GenServer.start_link(__MODULE__, state, opts)
  end

  def handle_call({:all}, _from, repo) do
    {:reply, repo.records, repo}
  end

  def handle_call({:where, filters}, _from, repo) do
    # filter records to that matches given filters
    matching_records = Enum.filter(repo.records, fn(record) ->
      Enum.reduce(filters, true, fn({filter_key,filter_value}, acc) ->
        # get record_key in atom that matches filter_key without
        # converting user input to atom that can cause memory leak
        record_key =
          Map.keys(record)
          |> Enum.find(fn(record_key) -> Atom.to_string(record_key) == filter_key end)

        # if user filter key matches key in record, compare its values
        case record_key do
          nil -> acc
          _ -> acc && Map.get(record, record_key) == filter_value
        end
      end)
    end)

    {:reply, matching_records, repo}
  end

  def handle_cast({:clear}, repo) do
    {:noreply, new_repo}
  end

  # insert new record to repo
  def handle_call({:insert!, record}, _from, repo) do
    record = %{ record | id: repo.last_id + 1 }

    case record.__struct__.validate_new(repo.records, record) do
      {:ok, new_record} -> {:reply, {:ok, new_record}, store_record(repo, new_record)}
      error -> {:reply, error, repo}
    end
  end

  # update
  def handle_call({:update!, record}, _from, repo) do
    original = Enum.find(repo.records, fn(r) -> r.id == record.id end)

    case record.__struct__.validate_update(repo.records, original, record) do
      {:ok, new_record} -> {:reply, {:ok, new_record}, store_update(repo, new_record)}
      error -> {:reply, error, repo}
    end
  end

  # count
  def handle_call({:count}, _from, repo) do
    {:reply, length(repo.records), repo}
  end


  # create new repo with new record
  defp store_record(repo, record) do
    %{
      last_id: record.id,
      records: repo.records |> Enum.concat([record])
    }
  end
  # create new repo with updated record
  defp store_update(repo, record) do
    %{
      repo |
      records: repo.records |> Enum.filter(fn(r) -> r.id != record.id end) |> Enum.concat([record])
    }
  end

  # Mimic Ecto interface

  # Insert record to repository based on record type
  def insert!(record) do
    GenServer.call(get_type_repo(record.__struct__), {:insert!, record})
  end

  # Insert record to repository based on record type
  def update!(record) do
    GenServer.call(get_type_repo(record.__struct__), {:update!, record})
  end

  # Get record by ID
  def get!(type, id) do
    # transform id to integer if it was in string
    {id_int, _} = case id do
      x when is_integer(x) -> {x, ""}
      x when is_bitstring(x) -> Integer.parse(x)
    end

    records = GenServer.call(get_type_repo(type), {:where, %{"id" => id_int}})
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

  def load_from_csv(GoustoApiTask.Recipe, file) do
    csv_stream =
      File.stream!(file) |>
      CSV.decode()

    header = csv_stream |> Enum.take(1) |> Enum.at(0)

    csv_stream |>
    Enum.drop(1) |>
    Enum.map(fn row ->
      # transform row with header to map, and apply to new record struct
      row_map = Enum.zip(header,row) |> Map.new()
      case GoustoApiTask.Recipe.merge(%GoustoApiTask.Recipe{}, row_map) do
        {:ok, recipe} -> insert! recipe
        _ -> nil
      end
    end)
  end

  # create empty structure for repo
  defp new_repo do
    %{
      last_id: 0,
      records: []
    }
  end
end
