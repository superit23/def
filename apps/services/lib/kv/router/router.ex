defmodule KV.Router do
  use GenServer

  @doc """
  BOTH NODES

  {:ok, _framework} = Services.Framework.start_link(
   %{discovery: [{Discovery.Nop, nil, %{nodes: ["foo@kali",
   "bar@kali"] }}],
   services: [], poll_interval: 500})
  Services.Framework.run
  {:ok, proc_registry} = Services.Registry.Mnesia.start_link
  {:ok, part_registry} = KV.Registry.Supervisor.start_link
  Services.Registry.register_name(proc_registry, to_string(node()) <> ".KV.Registry", KV.Registry)
  {:ok, router} = KV.Router.start_link(proc_registry)

  ONE NODE
  KV.Router.create_partition(router, "bucketbois")
  """

  def start_link(registry_server) do
    GenServer.start_link(__MODULE__, registry_server)
  end


  def init(registry_server) do
    {:ok, {registry_server, []}}
  end


  def create_partition(pid, partition) do
    GenServer.call(pid, {:create, partition})
  end


  def handle_call({:create, partition}, _from, {registry_server, partitions}) do
    h_func = fn val -> :erlang.phash2(val) end
    {h_nodes, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(
       Enum.map([node()] ++ Node.list, fn node -> to_string(node) end), h_func)

    [{^partition, assigned_node}] = Algorithms.ConsistentHashing.find(
      partition, h_nodes, hash_map, h_func)

    remote_registry = Services.Registry.whereis_name(
      registry_server, assigned_node <> ".KV.Registry")

    pid = KV.Registry.create(remote_registry, partition)

    {:reply, {assigned_node, pid}, {registry_server, [partition] ++ partitions}}
  end



end
