defmodule GoustoApiTask.RecipeControllerTest do
  use GoustoApiTask.ConnCase

  alias GoustoApiTask.Recipe
  alias GoustoApiTask.Repo

  @valid_attrs %{recipe_cuisine: "some content", slug: "some-content", title: "some content"}
  @invalid_attrs %{}

  # Setup JSON-API MIME headers
  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    # wipe Repo
    Repo.clear(Recipe)

    { :ok, conn: conn }
  end

  # Fetch a recipe by id

  test "GET /api/recipes/:id respond with 200 when id exists", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    conn = get conn, "/api/recipes/#{recipe.id}"

    response_data = json_response(conn, 200)["data"]
    assert response_data["id"] == to_string(recipe.id)
    assert response_data["type"] == "recipes"

    response_attributes = response_data["attributes"]
    assert response_attributes = %{ "title" => recipe.title }
  end

  test "GET /api/recipes/:slug respond with 200 when id exists", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    conn = get conn, "/api/recipes/#{recipe.slug}"

    response_data = json_response(conn, 200)["data"]
    assert response_data["id"] == to_string(recipe.id)
    assert response_data["type"] == "recipes"

    response_attributes = response_data["attributes"]
    assert response_attributes = %{ "title" => recipe.title }
  end


  test "GET /api/recipes/:id respond with 404 when id doesn't exists", %{conn: conn} do
    conn = get conn, "/api/recipes/-1"
    assert conn.status == 404
  end

  # Fetch all recipes for a specific cuisine

  test "GET /api/recipes using respond 200 with list of all records", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    {:ok, recipe_other} = Repo.insert %Recipe{
      title: "Pork Chilli 2",
      slug: "pork-chilli-2",
      recipe_cuisine: "british"
    }

    conn = get conn, "/api/recipes"
    response = json_response(conn, 200)
    assert length(response["data"]) == 2
    assert (response["data"] |> Enum.at(0))["id"] == to_string(recipe.id)
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == recipe.title
  end


  test "GET /api/recipes respond empty list when no records exists", %{conn: conn} do
    conn = get conn, "/api/recipes?filter[recipe_cuisine]=asian"
    assert json_response(conn, 200)["data"] == []
  end

  test "GET /api/recipes using filter[recipe_cuisine] respond 200 with list of records of that cuisine", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: "pork-chilli",
      recipe_cuisine: "asian"
    }
    {:ok, recipe_other} = Repo.insert %Recipe{
      title: "Pork Chilli 2",
      slug: "pork-chilli-2",
      recipe_cuisine: "british"
    }

    conn = get conn, "/api/recipes?filter[recipe_cuisine]=asian"
    response = json_response(conn, 200)
    assert length(response["data"]) == 1
    assert (response["data"] |> Enum.at(0))["id"] == to_string(recipe.id)
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == recipe.title
  end

  test "GET /api/recipes respond with paginated list", %{conn: conn} do
    # create 150 Pork Chilli recipes
    Enum.each 1..150, fn(n) ->
      Repo.insert %Recipe{
       title: "Pork Chilli #{n}",
       slug: "pork-chilli-#{n}",
       recipe_cuisine: "asian"
     }
    end

    conn = get conn, "/api/recipes?filter[recipe_cuisine]=asian"
    response = json_response(conn, 200)
    assert length(response["data"]) == 50
    assert response["links"]["next"] != nil
    assert (response["data"] |> Enum.at(0))["attributes"]["title"] == "Pork Chilli 1"

    conn = get conn, "/api/recipes?filter[recipe_cuisine]=asian&page[offset]=50"
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
    assert Repo.get!(Recipe, json_response(conn, 201)["data"]["id"]) != nil
  end

  test "POST - it respond 422 if slug already exists", %{conn: conn} do
    Repo.insert %Recipe{
      title: "Pork Chilli",
      slug: @valid_attrs.slug,
      recipe_cuisine: "asian"
    }

    conn = post conn, "/api/recipes", %{
      data: %{
        type: "recipes",
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 422)
    assert Enum.at(json_response(conn, 422)["errors"], 0)["source"] == "/data/attributes/slug"
  end

  test "POST - it creates with timestamps", %{conn: conn} do
    conn = post conn, "/api/recipes", %{
      data: %{
        type: "recipes",
        attributes: @valid_attrs
      }
    }
    assert json_response(conn, 201)["data"]["id"] != nil
    assert json_response(conn, 201)["data"]["attributes"]["created_at"] != nil
    assert json_response(conn, 201)["data"]["attributes"]["updated_at"] != nil
  end

  test "POST - it respond 422 with invalid attributes", %{conn: conn} do
    conn = post conn, "/api/recipes", %{
      data: %{
        type: "recipes",
        attributes: %{
          recipe_title: "Title"
        }
      }
    }
    assert json_response(conn, 400)
    assert Enum.at(json_response(conn, 400)["errors"], 0)["source"] == "/data/attributes/recipe_title"
  end


  # Update an exising recipe

  test "PUT - updates and renders chosen resource when data is valid", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Recipe",
      recipe_cuisine: "asian"
    }
    conn = put conn, "/api/recipes/#{recipe.id}", %{
      data: %{
        type: "recipes",
        id: recipe.id,
        attributes: %{
          title: "New Title 2"
        }
      }
    }
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get!(Recipe, json_response(conn, 200)["data"]["id"])
    assert Repo.get!(Recipe, json_response(conn, 200)["data"]["id"]).title == "New Title 2"
  end

  test "PUT - does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    {:ok, recipe} = Repo.insert %Recipe{
      title: "Recipe",
      recipe_cuisine: "asian"
    }
    conn = put conn, recipe_path(conn, :update, recipe), %{
      data: %{
        type: "recipes",
        id: recipe.id,
        attributes: %{
          title: ""
        }
      }
    }
    assert json_response(conn, 422)["errors"] != %{}
  end

end
