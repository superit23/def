defmodule Discovery.Mesos do

  @moduledoc """
  Uses an existing instance of Apache Mesos to find other DEF nodes.
  Using the given framework name, DEF assumes the containers under the currently
  running tasks are DEF nodes and formatted as FRAMEWORK@IP_ADDRESS.
  """

  @behaviour Discovery.Strategy

  @doc """
  Initializes the Mesos integration with the API `url`.
  """
  def start_link(url \\"http://leader.mesos:5050/v1/api") do
    Integrations.Mesos.start_link(url)
  end


  @doc """
  Discovers the nodes by container IP addresses given the `framework`.
  """
  def discover(%{framework: framework}) do
    Integrations.Mesos.get_frameworks.body["frameworks"]
     |> Enum.filter(&(&1["name"] == framework))
     |> Enum.at(0)
     |> Map.get("tasks")
     |> Enum.map(&(&1["statuses"]))
     |> List.flatten
     |> Enum.map(&(&1["container_status"]["network_infos"]))
     |> List.flatten
     |> Enum.map(&(&1["ip_addresses"]))
     |> List.flatten
     |> Enum.map(&(framework <> "@" <> &1["ip_address"]))
  end
end
