defmodule Discovery.Mesos do

  @behaviour Discovery.Strategy

  def start_link(url \\"http://marathon.mesos:8080/v2/") do
    Integrations.Mesos.start_link(url)
  end


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
