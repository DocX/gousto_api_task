defmodule GoustoApiTask.Plugs.LoadDataFromCSV do
  import Plug.Conn
  alias GoustoApiTask.RecipeCSVLoader
  alias GoustoApiTask.Repo

  def init(default), do: default

  def call(conn, _) do
    case {System.get_env("CSV_DATA_FILE"), Repo.count(GoustoApiTask.Recipe)} do
      {nil, _} ->
        conn
      {file_name, 0} ->
        RecipeCSVLoader.load_from_csv(file_name)
        conn
      _ ->
        conn
    end
  end
end
