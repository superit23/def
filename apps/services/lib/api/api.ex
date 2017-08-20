defmodule Services.Api do
  use Maru.Router

  # {host}:{port}/{service_namespace}/{routes}

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json]

  mount KV.Router.Api

  # rescue_from :all do
  #   conn
  #   |> put_status(500)
  #   |> text("Server error")
  # end

end
