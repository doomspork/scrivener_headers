defmodule Scrivener.HeadersTests do
  use ExUnit.Case, async: true

  alias Plug.Conn
  alias Scrivener.{Headers, Page}

  defp paginated_headers(page, port \\ 80) do
    conn = %Conn{host: "www.example.com",
                 port: port,
                 query_string: "foo=bar",
                 request_path: "/test",
                 scheme: :http}
            |> Headers.paginate(page)

    conn.resp_headers
    |> Enum.into(%{})
  end

  test "add pagination headers" do
    page = %Page{page_number: 3, page_size: 10, total_pages: 5, total_entries: 50}
    headers = paginated_headers(page)

    assert headers["total"] == "50"
    assert headers["per-page"] == "10"
    assert headers["total-pages"] == "5"
    assert headers["page-number"] == "3"
    links = String.split(headers["link"], ", ")
    assert ~s(<http://www.example.com/test?foo=bar&page=1>; rel="first") in links
    assert ~s(<http://www.example.com/test?foo=bar&page=5>; rel="last") in links
    assert ~s(<http://www.example.com/test?foo=bar&page=4>; rel="next") in links
    assert ~s(<http://www.example.com/test?foo=bar&page=2>; rel="prev") in links
  end

  test "doesn't include prev link for first page" do
    page = %Page{page_number: 1, page_size: 10, total_pages: 5, total_entries: 50}
    headers = paginated_headers(page)

    refute headers["link"] =~ ~s(rel="prev")
  end

  test "doesn't include next link for last page" do
    page = %Page{page_number: 5, page_size: 10, total_pages: 5, total_entries: 50}
    headers = paginated_headers(page)

    refute headers["link"] =~ ~s(rel="next")
  end

  test "includes ports other than 80 and 443" do
    page = %Page{page_number: 5, page_size: 10, total_pages: 5, total_entries: 50}
    headers = paginated_headers(page, 1337)

    assert headers["link"] =~ ~s(<http://www.example.com:1337/test?foo=bar&page=1>)
  end
end
