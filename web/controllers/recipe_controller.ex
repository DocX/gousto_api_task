defmodule GoustoApiTask.RecipeController do
  use GoustoApiTask.Web, :controller

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.Repo

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

    render(conn, "index.json", recipes: all_recipes, offset: page_offset, limit: page_limit)
  end

  def create(conn, %{"data" => %{ "attributes" => attrs, "type" => "recipes"}}) do
    changeset = Recipe.merge(%Recipe{}, attrs)

    case Repo.insert!(changeset) do
      {:ok, recipe} ->
        conn
        |> put_status(:created)
        |> render("show.json", recipe: recipe)
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
      render(conn, "show.json", recipe: recipe)
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
