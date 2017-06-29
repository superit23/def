defmodule Discovery.Strategy do

  @moduledoc """
  A discovery strategy is a mechanism for nodes to find other nodes without
  explicit user input. Multiple discovery strategies can be used and aggregated
  to allow for fault-tolerance or connection across partitions.
  """

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
