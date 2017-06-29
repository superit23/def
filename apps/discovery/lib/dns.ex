defmodule Discovery.Dns do

  @behaviour Discovery.Strategy

  def start_link(_args \\ "") do
    {:ok}
  end


  def discover(%{service: service, hostname: hostname}) do
    :inet_res.lookup(to_charlist(hostname), :in, :a) |>
    Enum.map(fn {a,b,c,d} ->
      service <> "@#{a}.#{b}.#{c}.#{d}"
    end)
  end
end
