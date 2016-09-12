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
    all_recipes = case params["filter"] do
      x when not is_nil(x) and is_map(x) -> Repo.all_where(Recipe, params["filter"])
      _ -> Repo.all(Recipe)
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
    changeset = Recipe.merge(%Recipe{}, attrs)

    case Repo.insert!(changeset) do
      {:ok, recipe} ->
        conn
        |> put_status(:created)
        |> render(:show, data: recipe)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(GoustoApiTask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    recipe = Repo.get!(Recipe, id)
    if is_nil(recipe) do
      conn
      |> send_resp(404, "")
    else
      render(conn, data: recipe)
    end
  end

  def update(conn, %{"id" => id, "data" => %{ "id" => id, "attributes" => attrs, "type" => "recipes"}}) do
    recipe = Repo.get!(Recipe, id)
    changeset = Recipe.merge(recipe, attrs)

    case Repo.update(changeset) do
      {:ok, recipe} ->
        render(conn, "show.json", recipe: recipe)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(GoustoApiTask.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
