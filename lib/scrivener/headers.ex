defmodule Scrivener.Headers do
  @moduledoc """
  Helpers for paginating API responses with [Scrivener](https://github.com/drewolson/scrivener) and HTTP headers. Implements [RFC-5988](https://mnot.github.io/I-D/rfc5988bis/), the proposed standard for Web linking.

  Use `paginate/2` to set the pagination headers:

      def index(conn, params) do
        page = MyApp.Person
               |> where([p], p.age > 30)
               |> order_by([p], desc: p.age)
               |> preload(:friends)
               |> MyApp.Repo.paginate(params)

        conn
        |> Scrivener.Headers.paginate(page)
        |> render("index.json", people: page.entries)
      end
  """

  import Plug.Conn, only: [put_resp_header: 3]

  @doc """
  Add HTTP headers for a `Scrivener.Page`.
  """
  @spec paginate(Plug.Conn.t, Scrivener.Page.t) :: Plug.Conn.t
  def paginate(conn, page) do
    uri = %URI{scheme: Atom.to_string(conn.scheme),
               host: conn.host,
               port: conn.port,
               path: conn.request_path,
               query: conn.query_string}
    conn
    |> put_resp_header("link", build_link_header(uri, page))
    |> put_resp_header("total", Integer.to_string(page.total_entries))
    |> put_resp_header("per-page", Integer.to_string(page.page_size))
    |> put_resp_header("total-pages", Integer.to_string(page.total_pages))
    |> put_resp_header("page-number", Integer.to_string(page.page_number))
  end

  @spec build_link_header(URI.t, Scrivener.Page.t) :: String.t
  defp build_link_header(uri, page) do
    [link_str(uri, 1, "first"),
     link_str(uri, page.total_pages, "last")]
    |> maybe_add_prev(uri, page.page_number, page.total_pages)
    |> maybe_add_next(uri, page.page_number, page.total_pages)
    |> Enum.join(", ")
  end

  defp link_str(%{query: req_query} = uri, page_number, rel) do
    query =
      req_query
      |> URI.decode_query()
      |> Map.put("page", page_number)
      |> URI.encode_query()
    uri_str =
      %URI{uri | query: query}
      |> URI.to_string()
    ~s(<#{uri_str}>; rel="#{rel}")
  end

  defp maybe_add_prev(links, uri, page_number, total_pages) when 1 < page_number and page_number <= total_pages do
    [link_str(uri, page_number - 1, "prev") | links]
  end
  defp maybe_add_prev(links, _uri, _page_number, _total_pages) do
    links
  end

  defp maybe_add_next(links, uri, page_number, total_pages) when 1 <= page_number and page_number < total_pages do
    [link_str(uri, page_number + 1, "next") | links]
  end
  defp maybe_add_next(links, _uri, _page_number, _total_pages) do
    links
  end
end
