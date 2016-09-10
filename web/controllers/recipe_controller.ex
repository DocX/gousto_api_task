defmodule GoustoApiTask.RecipeController do
  use GoustoApiTask.Web, :controller

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.Repo

  def index(conn, _params) do
    recipes = Repo.all(Recipe)
    render(conn, "index.json", recipes: recipes)
  end

  def create(conn, %{"recipe" => recipe_params}) do
    changeset = Recipe.changeset(%Recipe{}, recipe_params)

    case Repo.insert(changeset) do
      {:ok, recipe} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", recipe_path(conn, :show, recipe))
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

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Repo.get!(Recipe, id)
    changeset = Recipe.changeset(recipe, recipe_params)

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
