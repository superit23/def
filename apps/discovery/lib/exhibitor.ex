defmodule Discovery.Exhibitor do

  @moduledoc """
  Uses an existing instance of Netflix Exhibitor to discover DEF nodes.
  With a supplied `url` and `base`, adds itself to `/base/key` and calls on the Exhibitor REST API
  for the key `base` to discover other nodes.
  """

  @behaviour Discovery.Strategy

  # "http://leader.mesos:8181/exhibitor/v1"

  @doc """
  Initializes the discovery mechanism with the Exhibitor REST API URL as well as
  the `base` key to add itself to.
  """
  def start_link(%{url: url, base: base}) do
    Integrations.Exhibitor.start_link(url)
    Integrations.Exhibitor.add_node(base <> "/" <> to_string(node()), to_string(node()))
  end

  @doc """
  Discovers other DEF nodes by querying the `base` key.
  """
  def discover(%{base: base}) do
    Integrations.Exhibitor.get_nodes(base).body
     |> Enum.map(&(&1["title"]))
  end
end
