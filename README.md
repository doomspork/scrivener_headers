# Scrivener.Headers

[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex] [![Hex docs][hexdocs-img]][hexdocs] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/doomspork/scrivener_headers.png?branch=master
[travis]: https://travis-ci.org/doomspork/scrivener_headers
[hex-img]: https://img.shields.io/hexpm/v/scrivener_headers.svg
[hex]: https://hex.pm/packages/scrivener_headers
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT
[hexdocs-img]: http://img.shields.io/badge/hex-docs-green.svg?style=flat
[hexdocs]: https://hexdocs.pm/scrivener_headers/Scrivener.Headers.html


Helpers for paginating API responses with [Scrivener](https://github.com/drewolson/scrivener) and HTTP headers.  Implements [RFC-5988](https://tools.ietf.org/html/rfc5988), the proposed standard for Web linking.

## Setup

Add to `mix.exs`:

```elixir
  defp deps do
    [
      # ...
      {:scrivener_headers, "~> 3.1"}
      # ...
    ]
  end
```

## Usage

With `paginate/2` we can easily set our pagination headers:

```elixir
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
```

With `curl --include` we can see our new headers:

```shell
$ curl --include 'https://localhost:4000/people?page=5'
HTTP/1.1 200 OK
Link: <http://localhost:4000/people?page=1>; rel="first",
  <http://localhost:4000/people?page=30>; rel="last",
  <http://localhost:4000/people?page=6>; rel="next",
  <http://localhost:4000/people?page=4>; rel="prev"
Total: 300
Per-Page: 10

```

Also it is possible to use custom header names:

```elixir
def index(conn, params) do
  page = MyApp.Person
         |> where([p], p.age > 30)
         |> order_by([p], desc: p.age)
         |> preload(:friends)
         |> MyApp.Repo.paginate(params, pagination_headers())

  conn
  |> Scrivener.Headers.paginate(page)
  |> render("index.json", people: page.entries)
end

defp pagination_headers, do: Application.get_env(:your_app, :pagination_headers)
```

We can override just the headers we want:

```elixir
config :your_app, :pagination_headers,
    link: "x-link",
    total: "x-total"
```

Or override all of them:

```elixir
config :your_app, :pagination_headers,
    link: "x-link",
    total: "x-total",
    per_page: "x-per-page",
    total_pages: "x-total-pages",
    page_number: "x-page-number"
```

## Contributing

Contributions of all types are welcomed and encouraged.  Please
make appropriate use of [Issues][issues] and [Pull Requests][pulls].  All code
should have test coverage.

[issues]: https://github.com/doomspork/scrivener_headers/issues
[pulls]: https://github.com/doomspork/scrivener_headers/pulls


## License

MIT license. Please see [LICENSE][license] for details.

[LICENSE]: https://github.com/doomspork/scrivener_headers/blob/master/LICENSE
