defmodule GoustoApiTask.Repo do
  use GenServer

  def start_link(state \\ [], opts \\ []) do
    state = case state do
      nil -> new_repo
      x -> x
    end
    GenServer.start_link(__MODULE__, state, opts)
  end

  def handle_call({:get_by, attrs}, _from, repo) do
    record = Enum.find(repo.records, nil, fn(record) ->
      case record do
        attrs -> true
        x -> false
      end
    end)

    {:reply, record, repo}
  end

  def handle_call({:all}, _from, repo) do
    {:reply, repo.records, repo}
  end

  def handle_call({:clear}, _from, repo) do
    {:reply, :ok, new_repo}
  end

  # insert new record to repo
  def handle_call({:insert!, record}, _from, repo) do
    record = %{ record | id: repo.last_id + 1 }
    next_repo = %{
      last_id: repo.last_id + 1,
      records: [record | repo.records]
    }

    { :reply, record, next_repo }
  end

  # Mimic Ecto interface

  # Insert record to repository based on record type
  def insert!(record) do
    GenServer.call(get_type_repo(record.__struct__), {:insert!, record})
  end

  # Get record by ID
  def get!(type, id) do
    GenServer.call(get_type_repo(type), {:get_by, %{id: id}})
  end

  # Get all records
  def all(type) do
    GenServer.call(get_type_repo(type), {:all})
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
