defmodule GoustoApiTask.RecipeRatingControllerTest do
  use GoustoApiTask.ConnCase

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.RecipeRating
  alias GoustoApiTask.Repo

  @valid_attrs %{recipe_id: 1, rating: 3}
  @invalid_attrs %{recipe_id: 1, rating: 6}

  # Setup JSON-API MIME headers
  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    # wipe Repo
    Repo.clear(Recipe)
    Repo.clear(RecipeRating)

    { :ok, conn: conn }
  end

  # Allow to rate recipes

  test "POST /api/recipes/:id/ratings respond with 201 when correct", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      recipe_cuisine: "asian"
    }

    conn = post conn, "/api/recipes/#{recipe.id}/ratings", %{
      data: %{
        type: "recipe_ratings",
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get!(Recipe, json_response(conn, 201)["data"]["id"]) != nil
  end

  test "POST /api/recipes/:id/ratings with non existing recipe respond 404", %{conn: conn} do
    conn = post conn, "/api/recipes/-1/ratings", %{
      data: %{
        type: "recipe_ratings",
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 404)
  end

  test "POST /api/recipes/:id/ratings with rating out of 1..5 range respond 422", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      recipe_cuisine: "asian"
    }

    conn = post conn, "/api/recipes/#{recipe.id}/ratings", %{
      data: %{
        type: "recipe_ratings",
        attributes: @invalid_attrs
      }
    }
    assert json_response(conn, 422)
    assert (json_response(conn, 422)["errors"] |> Enum.at(0))["source"] == "/data/attributes/rating"
  end

  # Get ratings

  test "GET /api/recipes/:recipe_id/ratings using respond 200 with list of all records", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    {:ok, rating} = Repo.insert %RecipeRating{
      recipe_id: recipe.id,
      rating: 5
    }

    conn = get conn, "/api/recipes/#{recipe.id}/ratings"
    response = json_response(conn, 200)
    assert length(response["data"]) == 1
    assert (response["data"] |> Enum.at(0))["attributes"]["rating"] == 5
  end

end
