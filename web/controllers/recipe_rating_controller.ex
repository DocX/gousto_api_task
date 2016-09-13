defmodule GoustoApiTask.RecipeRatingController do
  use GoustoApiTask.Web, :controller

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.RecipeRating
  alias GoustoApiTask.Repo
  alias GoustoApiTask.Pagination
  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  plug :load_recipe

  defp load_recipe(conn, _) do
    case Repo.get!(Recipe, conn.params["recipe_id"]) do
      nil ->
        conn |> put_status(:not_found) |> render(GoustoApiTask.ErrorView, "errors.json-api", errors: [{:recipe_id, "Does not exists"}]) |> halt
      recipe ->
        conn |> assign(:recipe, recipe)
    end
  end

  def index(conn, params) do
    all_ratings = Repo.all(RecipeRating)

    # parse pagination parameters
    page_offset = case Integer.parse(params["page"]["offset"] || "") do
      {x, _} -> x
      :error -> 0
    end
    page_limit = case Integer.parse(params["page"]["offset"] || "") do
      {x, _} -> x
      :error -> 50
    end

    ratings = Pagination.paginate(all_ratings, page_offset, page_limit)
    page_links = Pagination.page_links(all_ratings, page_offset, page_limit, &recipe_url(Endpoint, :index, &1))

    render(conn, data: ratings, opts: [page: page_links])
  end

  def create(conn, %{"recipe_id" => recipe_id, "data" => %{"type" => "recipe_ratings", "attributes" => attrs}}) do
    attrs = %{attrs | "recipe_id" => recipe_id}

    # try to merge user params to new record model
    # if merged successfuly, insert to repo and get result
    # otherwise use error from merge as error for render
    result = case RecipeRating.merge(%RecipeRating{}, attrs) do
      {:ok, rating} -> Repo.insert!(rating)
      {:error, errors} -> {:bad_request, errors}
    end

    # render result
    case result do
      {:ok, rating} ->
        conn
        |> put_status(:created)
        |> render(:show, data: rating)
      {:bad_request, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(GoustoApiTask.ErrorView, "errors.json-api", errors: errors)
      {:error, errors} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(GoustoApiTask.ErrorView, "errors.json-api", errors: errors)
    end
  end

end
