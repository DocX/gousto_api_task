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

  def handle_call({:clear}, _from, repo) do
    {:reply, :ok, new_repo}
  end

  # insert new record to repo
  def handle_call({:insert!, record}, _from, repo) do
    record = %{ record | id: repo.last_id + 1 }
    next_repo = %{
      last_id: repo.last_id + 1,
      records: repo.records |> Enum.concat([record])
    }

    { :reply, {:ok, record}, next_repo }
  end

  # Mimic Ecto interface

  # Insert record to repository based on record type
  def insert!(record) do
    GenServer.call(get_type_repo(record.__struct__), {:insert!, record})
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
    GenServer.call(get_type_repo(type), {:clear})
  end

  # Get repo name for record type
  defp get_type_repo(type) do
    case type do
      GoustoApiTask.Recipe -> RecipesRepo
    end
  end

  defp new_repo do
    %{
      last_id: 0,
      records: []
    }
  end
end
