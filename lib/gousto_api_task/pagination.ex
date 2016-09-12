defmodule GoustoApiTask.Pagination do
  # limit given list to given page
  def paginate(list, offset, limit) do
    list
    |> Enum.drop(offset)
    |> Enum.take(limit)
  end

  # Return pagination links
  def page_links(list, offset, limit, url_fn) do
    %{
      first: url_fn.(page: %{ offset: 0, limit: limit }),
      prev: case offset do
        x when x - limit >= 0 -> url_fn.(page: %{ offset: x - limit, limit: limit})
        _ -> nil
      end,
      next: case offset + limit do
        x when x < length(list) -> url_fn.(page: %{offset: x, limit: limit})
        _ -> nil
      end,
      last: url_fn.(page: %{
        offset: case length(list) - limit do
          x when x >= 0 -> x;
          _ -> 0
        end,
        limit: limit
        })
    }
  end
end
