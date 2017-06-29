defmodule Discovery.Exhibitor do

  @behaviour Discovery.Strategy

  # "http://leader.mesos:8181/exhibitor/v1"
  def start_link(%{url: url, base: base}) do
    Integrations.Exhibitor.start_link(url)
    Integrations.Exhibitor.add_node(base <> "/" <> to_string(node()), to_string(node()))
  end


  def discover(%{base: base}) do
    Integrations.Exhibitor.get_nodes(base).body
     |> Enum.map(&(&1["title"]))
  end
end
