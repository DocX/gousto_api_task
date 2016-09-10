defmodule GoustoApiTask.RecipeControllerTest do
  use GoustoApiTask.ConnCase

  alias GoustoApiTask.Recipe
  @valid_attrs %{recipe_cuisine: "some content", slug: "some-content", title: "some content"}
  @invalid_attrs %{}

  # Setup JSON-API MIME headers
  setup %{conn: conn} do
    {
      :ok,
      conn:
        conn
        |> put_req_header("accept", "application/vnd.api+json")
        |> put_req_header("content-type", "application/vnd.api+json")
    }
  end

  # Fetch a recipe by id

  test "Fetch a recipe by id - existing", %{conn: conn} do
    recipe = Repo.insert! %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    conn = get conn, "/api/recipes/#{recipe.id}"

    response_data = json_response(conn, 200)["data"]
    assert response_data["id"] == recipe.id
    assert response_data["type"] == "recipes"

    response_attributes = response_data["attributes"]
    assert response_attributes = %{ "title" => recipe.title }
  end

  test "Fetch a recipe by id - not found", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, "/api/recipes/-1"
    end
  end

  # Fetch all recipes for a specific cuisine

  test "Fetch all recipes for a specific cuisine - get empty", %{conn: conn} do
    conn = get conn, "/api/recipes?filter[cuisine]=asian"
    assert json_response(conn, 200)["data"] == []
  end

  test "Fetch all recipes for a specific cuisine - get", %{conn: conn} do
    recipe = Repo.insert! %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    recipe_other = Repo.insert! %Recipe{
      title: "Pork Chilli 2",
      slug: "pork-chilli-2",
      recipe_cuisine: "british"
    }

    conn = get conn, "/api/recipes?filter[cuisine]=asian"
    response = json_response(conn, 200)
    assert length(response["data"]) == 1
    assert (response["data"] |> Enum.at(0))["id"] == recipe.id
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == recipe.title
  end

  test "Fetch all recipes for a specific cuisine - pagination", %{conn: conn} do
    # create 150 Pork Chilli recipes
    Enum.each 1..150, fn(n) ->
      Repo.insert! %Recipe{
       title: "Pork Chilli #{n}",
       slug: "pork-chilli-#{n}",
       recipe_cuisine: "asian"
     }
    end

    conn = get conn, "/api/recipes?filter[cuisine]=asian"
    response = json_response(conn, 200)
    assert length(response["data"]) == 50
    assert response["links"]["next"] != nil
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == "Pork Chilli 1"

    conn = get conn, "/api/recipes?filter[cuisine]=asian&page[number]=2"
    response = json_response(conn, 200)
    assert length(response["data"]) == 50
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == "Pork Chilli 51"
  end


  # Store a new recipe

  test "POST - it respond 201 and stores new recipe with valid attributes", %{conn: conn} do
    conn = post conn, "/api/recipes", %{
      data: %{
        type: "recipes",
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Recipe, id: json_response(conn, 201)["data"]["id"])
  end

  test "POST - it respond with 400 and doesn't store new recipe with invalid attrs", %{conn: conn} do
    conn = post conn, "/api/recipes", %{
      data: %{
        type: "recipes",
        attributes: @invalid_attrs
      }
    }
    assert json_response(conn, 400)["errors"] != %{}
  end


  # Update an exising recipe

  test "PATCH - updates and renders chosen resource when data is valid", %{conn: conn} do
    recipe = Repo.insert! %Recipe{}
    conn = put conn, "/api/recipes/#{recipe.id}", %{
      data: %{
        type: "recipes",
        id: recipe.id,
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Recipe, @valid_attrs)
  end

  test "PATCH - does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    recipe = Repo.insert! %Recipe{}
    conn = put conn, recipe_path(conn, :update, recipe), %{
      data: %{
        type: "recipes",
        id: recipe.id,
        attributes: @invalid_attrs
      }
    }
    assert json_response(conn, 400)["errors"] != %{}
  end

end
