defmodule GoustoApiTask.RecipeTest do
  use GoustoApiTask.ModelCase

  alias GoustoApiTask.Recipe

  @valid_attrs %{recipe_cuisine: "some content", slug: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Recipe.changeset(%Recipe{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Recipe.changeset(%Recipe{}, @invalid_attrs)
    refute changeset.valid?
  end
end
