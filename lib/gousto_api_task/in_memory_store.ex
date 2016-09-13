defmodule GoustoApiTask.InMemoryStore do
  use GenServer

  # initialize server with empty store
  def start_link(state \\ [], opts \\ []) do
    state = case state do
      nil -> new_repo
      x -> x
    end
    GenServer.start_link(__MODULE__, state, opts)
  end

  # get all records
  def handle_call({:all}, _from, repo) do
    {:reply, repo.records, repo}
  end

  # get records matching all fields in filters map using == comparator
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

  # empty store
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

  # update record
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

  # create empty structure for repo
  defp new_repo do
    %{
      last_id: 0,
      records: []
    }
  end
end
