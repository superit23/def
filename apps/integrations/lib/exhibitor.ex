defmodule Integrations.Exhibitor do
  use Tesla
  use GenServer

  @moduledoc """
  Integrates with Netflix Exhibitor, a supervisor and API frontend for Zookeeper.
  """

  plug Tesla.Middleware.DecodeJson
  plug Tesla.Middleware.Headers, %{"User-Agent" => "DEF 0.1 (httpc)"}


  # Here we use ibrowse instead of httpc for our HTTP library because
  # httpc doesn't include Content-Type headers on DELETE requests.
  # When using `delete_node` on an Exhibitor instance,
  # this would cause "400 Bad Request" responses.
  adapter Tesla.Adapter.Ibrowse


  ## Init
  @doc "Initializes the module and sets the API URL."
  def start_link(baseURL \\ "http://leader.mesos:8181/exhibitor/v1") do
    GenServer.start_link(__MODULE__, baseURL, name: Exhibitor)
  end

  def init(baseURL) do
    {:ok, baseURL}
  end


  ## Public API
  @doc "Takes in node/key in /path/to/node format and returns sub-nodes."
  def get_nodes(key \\ "") do
    GenServer.call(Exhibitor, {:get_nodes, key})
  end


  @doc "Modifies or creates a node with the provided data."
  def add_node(key, data) do
    GenServer.call(Exhibitor, {:add_node, key, data})
  end


  @doc "Deletes a node from Exhibitor."
  def delete_node(key) do
    GenServer.call(Exhibitor, {:delete_node, key})
  end



  ## GenServer API
  def handle_call({:get_nodes, key}, _from, baseURL) do
    {:reply, get(baseURL <> "/explorer/node?key=" <> key), baseURL}
  end


  def handle_call({:add_node, key, data}, _from, baseURL) do
    {:reply, put(baseURL <> "/explorer/znode" <> key, Base.encode16(data),
     headers: %{"Content-Type" => "application/json"}), baseURL}
  end


  def handle_call({:delete_node, key}, _from, baseURL) do
    {:reply, delete(baseURL <> "/explorer/znode" <> key,
     headers: %{"Content-Type" => "application/json"}), baseURL}
  end

end
