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
  {assigned_node, bucket} = KV.Router.create_bucket(proc_registry, "bucket_test", 6, 3)
  KV.Bucket.write(bucket, {"key", "value"})
  KV.Bucket.lookup(bucket, "key")
  """

  def start_link(proc_registry) do
    GenServer.start_link(__MODULE__, proc_registry, name: KV.Router)
  end


  def init(proc_registry) do
    {:ok, {proc_registry, []}}
  end


  def get_state do
    GenServer.call(KV.Router, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end


  def create_partition(proc_registry, partition) do
    #assigned_node = get_assigned_node(partition)
    assigned_node = get_assigned_part([node()] ++ Node.list, partition)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    #KV.Registry.create(remote_registry, partition)
    pid = KV.Registry.create(remote_registry, partition, true, fn ->
      KV.Partition.Supervisor.start_partition
    end)

    {assigned_node, pid}
  end


  def lookup(proc_registry, name) do
    assigned_node = get_assigned_part([node()] ++ Node.list, name)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    pid = KV.Registry.lookup_call!(remote_registry, name)

    {assigned_node, pid}
  end


  def create_bucket(proc_registry, bucket, num_partitions, replication_factor) do
    assigned_node = get_assigned_part([node()] ++ Node.list, bucket)

    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    #pid = KV.Registry.create_bucket(remote_registry, bucket, num_partitions, replication_factor)
    pid = KV.Registry.create(remote_registry, bucket, true, fn ->
      KV.Bucket.Supervisor.start_bucket(bucket, num_partitions, replication_factor)
    end)

    KV.Bucket.init_partitions(pid, proc_registry)
    {assigned_node, pid}
  end


  def create_raft(proc_registry, part_string, assigned_node, pid) do
    remote_registry = Services.Registry.whereis_name(
      proc_registry, assigned_node <> ".KV.Registry")

    KV.Registry.create(remote_registry, part_string, false, fn ->
      {:ok, cache} = Storage.Ets.start_link
      {:ok, commit} = Storage.Partition.start_link(pid)
      Algorithms.Raft.start_link(commit, cache, part_string)
    end)
  end


  def get_assigned_part(list, item) do
    h_func = fn val -> :erlang.phash2(val) end

    list_partitions = Enum.map(list,
    fn list_item ->
      Enum.map(1..32,
      fn x ->
        to_string(list_item) <> "$" <> to_string(x)
      end)
    end) |> List.flatten


    {h_list, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(
       list_partitions, h_func)


    [{^item, assigned_part}] = Algorithms.ConsistentHashing.find(
      item, h_list, hash_map, h_func)

      Enum.at(String.split(assigned_part, "$"), 0)
  end



end
