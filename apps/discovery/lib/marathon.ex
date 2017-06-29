defmodule Discovery.Marathon do

  @moduledoc """
  Uses an existing instance of Mesosphere Marathon to find other DEF nodes.
  Given the `service`, we simply find the current tasks and extract the hosts.
  DEF nodes are assumed to be in SERVICE@HOST format.
  """

  @behaviour Discovery.Strategy

  @doc """
  Initializes the discovery mechanism with the Marathon API `url`.
  """
  def start_link(url \\"http://marathon.mesos:8080/v2") do
    Integrations.Marathon.start_link(url)
  end

  @doc """
  Returns hosts running tasks for the given `service`.
  """
  def discover(%{service: service}) do
    Integrations.Marathon.get_tasks(service).body["tasks"]
     |> Enum.map(&(service <> "@" <> &1["host"]))
  end
end
