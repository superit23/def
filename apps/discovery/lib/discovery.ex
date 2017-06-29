defmodule Discovery.Strategy do
  @doc """
  Initialization of strategy.
  May be a NOP.
  """
  @callback start_link(any) :: any

  @doc """
  Arguments for discovery specific to the strategy.
  Always takes a Map.
  """
  @callback discover(any) :: [String.t]
end
