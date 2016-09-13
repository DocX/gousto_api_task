defmodule GoustoApiTask.Plugs.LoadDataFromCSV do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _) do
    case {System.get_env("CSV_DATA_FILE"), GoustoApiTask.Repo.count(GoustoApiTask.Recipe)} do
      {nil, _} ->
        conn
      {file_name, 0} ->
        GoustoApiTask.Repo.load_from_csv(GoustoApiTask.Recipe, file_name)
        conn
      _ ->
        conn
    end
  end
end
