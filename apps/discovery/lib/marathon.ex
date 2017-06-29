defmodule Discovery.Marathon do

  @behaviour Discovery.Strategy

  def start_link(url \\"http://marathon.mesos:8080/v2") do
    Integrations.Marathon.start_link(url)
  end


  def discover(%{service: service}) do
    Integrations.Marathon.get_tasks(service).body["tasks"]
     |> Enum.map(&(service <> "@" <> &1["host"]))
  end
end
