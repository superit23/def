defmodule Discovery.Nop do

  @moduledoc """
  Simply takes the list of nodes from the user to give to DEF.
  """

  @behaviour Discovery.Strategy

  @doc """
  Initializes the module. Takes no arguments; NOP.
  """
  def start_link(_args \\ "") do
    {:ok}
  end

  @doc """
  Takes a list of `nodes` to return to DEF.
  """
  def discover(%{nodes: nodes}) do
    nodes
  end
end
