defmodule GoustoApiTask.RecipeCSVLoader do
  alias GoustoApiTask.Repo
  require Logger

  # loads recipe records from CSV with normalizing data types
  def load_from_csv(file) do
    csv_stream =
      File.stream!(file) |>
      CSV.decode()

    header = csv_stream |> Enum.take(1) |> Enum.at(0)

    rows = Enum.count(csv_stream) - 1

    loaded =
      csv_stream |>
      Enum.drop(1) |>
      Enum.map(fn row ->
        # transform row with header to map, and apply to new record struct
        row_map = Enum.zip(header,row) |> Map.new()
        row_map = %{
          row_map |
          "created_at" =>
            Timex.parse!(row_map["created_at"], "%d/%m/%Y %H:%M:%S", :strftime) |>
            Timex.to_unix |>
            DateTime.from_unix!() ,
          "updated_at" =>
            Timex.parse!(row_map["updated_at"], "%d/%m/%Y %H:%M:%S", :strftime) |>
            Timex.to_unix |>
            DateTime.from_unix!()
        }
        case GoustoApiTask.Recipe.merge(%GoustoApiTask.Recipe{}, row_map) do
          {:ok, recipe} -> Repo.insert recipe
          _ -> nil
        end
      end) |>
      Enum.filter(fn(i) -> i != nil end) |>
      length

    Logger.info "CSV loaded: #{loaded}/#{rows} recipes loaded from CSV"
  end
end
