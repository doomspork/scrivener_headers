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

  import Plug.Conn, only: [put_resp_header: 3, get_req_header: 2]

  @default_header_keys %{
    link: "link",
    total: "total",
    per_page: "per-page",
    total_pages: "total-pages",
    page_number: "page-number"
  }

  @doc """
  Add HTTP headers for a `Scrivener.Page`.
  """
  @spec paginate(Plug.Conn.t(), Scrivener.Page.t(), opts :: keyword()) :: Plug.Conn.t()
  def paginate(conn, page, opts \\ [])

  def paginate(conn, page, opts) do
    use_x_forwarded = Keyword.get(opts, :use_x_forwarded, false)
    header_keys = generate_header_keys(opts)
    uri = generate_uri(conn, use_x_forwarded)
    do_paginate(conn, page, uri, header_keys)
  end

  defp generate_uri(conn, true) do
    %URI{
      scheme: get_x_forwarded_or_conn(conn, :scheme, "proto", &Atom.to_string/1),
      host: get_x_forwarded_or_conn(conn, :host, "host"),
      port: get_x_forwarded_or_conn(conn, :port, "port", & &1, &String.to_integer/1),
      path: conn.request_path,
      query: conn.query_string
    }
  end

  defp generate_uri(conn, false) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: conn.request_path,
      query: conn.query_string
    }
  end

  defp do_paginate(conn, page, uri, header_keys) do
    conn
    |> put_resp_header(header_keys.link, build_link_header(uri, page))
    |> put_resp_header(header_keys.total, Integer.to_string(page.total_entries))
    |> put_resp_header(header_keys.per_page, Integer.to_string(page.page_size))
    |> put_resp_header(header_keys.total_pages, Integer.to_string(page.total_pages))
    |> put_resp_header(header_keys.page_number, Integer.to_string(page.page_number))
  end

  defp get_x_forwarded_or_conn(
         conn,
         conn_prop,
         header_name,
         parse_conn \\ & &1,
         parse_header \\ & &1
       ) do
    case get_req_header(conn, "x-forwarded-#{header_name}") do
      [] -> conn |> Map.get(conn_prop) |> parse_conn.()
      [value | _] -> parse_header.(value)
    end
  end

  @spec build_link_header(URI.t(), Scrivener.Page.t()) :: String.t()
  defp build_link_header(uri, page) do
    [link_str(uri, 1, "first"), link_str(uri, page.total_pages, "last")]
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

  defp maybe_add_prev(links, uri, page_number, total_pages)
       when 1 < page_number and page_number <= total_pages do
    [link_str(uri, page_number - 1, "prev") | links]
  end

  defp maybe_add_prev(links, _uri, _page_number, _total_pages) do
    links
  end

  defp maybe_add_next(links, uri, page_number, total_pages)
       when 1 <= page_number and page_number < total_pages do
    [link_str(uri, page_number + 1, "next") | links]
  end

  defp maybe_add_next(links, _uri, _page_number, _total_pages) do
    links
  end

  defp generate_header_keys(header_keys: header_keys) do
    custom_header_keys = Map.new(header_keys)

    Map.merge(@default_header_keys, custom_header_keys)
  end

  defp generate_header_keys(_), do: @default_header_keys
end
