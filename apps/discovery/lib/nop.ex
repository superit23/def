defmodule Discovery.Nop do

  @behaviour Discovery.Strategy

  def start_link(_args \\ "") do
    {:ok}
  end

  def discover(%{nodes: nodes}) do
    nodes
  end
end
