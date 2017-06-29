defmodule Discovery.Dns do

  @moduledoc """
  Uses DNS to find other DEF nodes. Currently implemented by using a `hostname`,
  the idea is multiples DEF nodes will be pointed at by a single, DNS entry.
  """

  @behaviour Discovery.Strategy

  @doc """
  Initializes the discovery mechanism. Takes no arguments; NOP.
  """
  def start_link(_args \\ "") do
    {:ok}
  end

  @doc """
  Resolves `hostname` to multiple A records, then prepends with `service`.
  """
  def discover(%{service: service, hostname: hostname}) do
    :inet_res.lookup(to_charlist(hostname), :in, :a) |>
    Enum.map(fn {a,b,c,d} ->
      service <> "@#{a}.#{b}.#{c}.#{d}"
    end)
  end
end
