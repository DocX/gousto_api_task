defmodule GoustoApiTask.RecipeController do
  use GoustoApiTask.Web, :controller

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.Repo
  alias GoustoApiTask.Pagination

  import GoustoApiTask.Router.Helpers
  alias GoustoApiTask.Endpoint

  def index(conn, params) do
    all_recipes = Repo.all(Recipe)

    # get records with filters
    all_recipes = case !is_nil(params["filter"]) && is_map(params["filter"]) do
      true -> Repo.all_where(Recipe, params["filter"])
      false -> Repo.all(Recipe)
    end

    # parse pagination parameters
    page_offset = case Integer.parse(params["page"]["offset"] || "") do
      {x, _} -> x
      :error -> 0
    end
    page_limit = case Integer.parse(params["page"]["offset"] || "") do
      {x, _} -> x
      :error -> 50
    end

    recipes = Pagination.paginate(all_recipes, page_offset, page_limit)
    page_links = Pagination.page_links(all_recipes, page_offset, page_limit, &recipe_url(Endpoint, :index, &1))

    render(conn, data: recipes, opts: [page: page_links])
  end

  def create(conn, %{"data" => %{"type" => "recipes", "attributes" => attrs}}) do
    # try to merge user params to new record model
    # if merged, insert to repo and get result
    result = case Recipe.merge(%Recipe{}, attrs) do
      {:ok, recipe} -> Repo.insert(recipe)
      {:error, errors} -> {:bad_request, errors}
    end

    # render result
    case result do
      {:ok, recipe} ->
        conn
        |> put_status(:created)
        |> render(:show, data: recipe)
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

  def show(conn, %{"id" => id}) do
    # get recipe based on id or slug based on type of parameter
    case get_by_id_or_slug!(id) do
      nil -> conn |> send_resp(404, "")
      recipe -> render(conn, data: recipe)
    end
  end

  def update(conn, %{"id" => id, "data" => %{ "attributes" => attrs, "type" => "recipes"}}) do
    recipe = get_by_id_or_slug!(id)
    result = case Recipe.merge(recipe, attrs) do
      {:ok, recipe} -> Repo.update(recipe)
      {:error, errors} -> {:bad_request, errors}
    end

    case result do
      {:ok, recipe} ->
        render(conn, :show, data: recipe)
      {:bad_request, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(GoustoApiTask.ErrorView, "errors.json-api", errors: errors)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(GoustoApiTask.ErrorView, "errors.json-api", errors: changeset)
    end
  end

  defp get_by_id_or_slug!(id) do
    case Integer.parse(id) do
      {id, ""} -> Repo.get!(Recipe, id)
      {number, rest} -> Repo.get_by!(Recipe, "slug", id)
      _ -> Repo.get_by!(Recipe, "slug", id)
    end
  end

end
