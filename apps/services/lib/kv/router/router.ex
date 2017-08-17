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
  {:ok, part_registry_super} = KV.Registry.Supervisor.start_link
  KV.Bucket.Supervisor.start_link
  part_registry = elem(Enum.at(Supervisor.which_children(part_registry_super), 1), 1)
  Services.Registry.register_name(proc_registry, to_string(node()) <> ".KV.Registry", part_registry)
  {:ok, router} = KV.Router.start_link(proc_registry)

  ONE NODE
  {:ok, bucket} = KV.Router.create_bucket(router, "bucket_test", 6, 3)
  {:ok, bucket} = KV.Bucket.start_link("bucket_test", 6, 3, router)
  """

  def start_link(proc_registry) do
    GenServer.start_link(__MODULE__, proc_registry)
  end


  def init(proc_registry) do
    {:ok, {proc_registry, []}}
  end


  def create_partition(pid, partition) do
    GenServer.call(pid, {:create_partition, partition})
  end


  def lookup_partition(pid, partition) do
    GenServer.call(pid, {:lookup_partition, partition})
  end


  def create_bucket(pid, bucket, num_partitions, replication_factor) do
    GenServer.call(pid, {:create_bucket, bucket, num_partitions, replication_factor})
  end


  defp get_assigned_node(partition) do
    h_func = fn val -> :erlang.phash2(val) end
    {h_nodes, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(
       Enum.map([node()] ++ Node.list, fn node -> to_string(node) end), h_func)

    [{^partition, assigned_node}] = Algorithms.ConsistentHashing.find(
      partition, h_nodes, hash_map, h_func)

      assigned_node
  end


  def handle_call({:create_partition, partition}, _from, {proc_registry, partitions}) do
    assigned_node = get_assigned_node(partition)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    pid = KV.Registry.create(remote_registry, partition)

    {:reply, {assigned_node, pid}, {proc_registry, [partition] ++ partitions}}
  end


  def handle_call({:lookup_partition, partition}, _from, {proc_registry, partitions}) do
    assigned_node = get_assigned_node(partition)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    pid = KV.Registry.lookup_call!(remote_registry, partition)

    {:reply, {assigned_node, pid}, {proc_registry, partitions}}
  end


  def handle_call({:create_bucket, bucket, num_partitions, replication_factor}, _from, {proc_registry, partitions}) do
    assigned_node = get_assigned_node(bucket)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    pid = KV.Registry.create_bucket(remote_registry, bucket, num_partitions, replication_factor, self())
    {:reply, {assigned_node, pid}, {proc_registry, partitions}}
  end


end
