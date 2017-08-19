defmodule KV.Bucket do
  use GenServer

  def start_link(name, num_partitions, replication_factor) do
    GenServer.start_link(__MODULE__,
      {name, num_partitions, replication_factor})
  end


  def init({name, num_partitions, replication_factor}) do
    {:ok, {name, %{}, num_partitions, replication_factor}}
  end


  def init_partitions(bucket, proc_registry) do
    GenServer.call(bucket, {:init_partitions, proc_registry})
  end


  def handle_call({:init_partitions, proc_registry}, _from, {name, %{}, num_partitions, replication_factor}) do
    part_raft_map = Enum.map(0..num_partitions, fn part_num ->
      part_string = name <> "_part_" <> to_string(part_num)

        raft_instances = Enum.map(0..replication_factor, fn rep_num ->
          {assigned_node, pid} = KV.Router.create_partition(proc_registry, part_string <> "_rep_" <> to_string(rep_num))
          KV.Router.create_raft(proc_registry, part_string, assigned_node, pid)
        end)

        {part_string, raft_instances}
      end)
      |> Enum.into(%{})

    # raft_instances = Enum.map(0..num_partitions, fn part_num ->
    #     Enum.map(0..replication_factor, fn rep_num ->
    #       part_string = name <> "_part_" <> to_string(part_num)
    #       {assigned_node, pid} = KV.Router.create_partition(proc_registry, part_string <> "_rep_" <> to_string(rep_num))
    #
    #       KV.Router.create_raft(proc_registry, part_string, assigned_node, pid)
    #      end)
    #    end)

    {:reply, :ok, {name, part_raft_map, num_partitions, replication_factor}}
  end


  def handle_call({:write, {key, value}}, _from, {name, part_raft_map, num_partitions, replication_factor}) do
    assigned_part = KV.Router.get_assigned_part(Map.keys(part_raft_map), key)
    Map.get(part_raft_map, assigned_part)
      |> Enum.at(0)
      |> Algorithms.Raft.write({key, value})

    {:reply, :ok, {name, part_raft_map, num_partitions, replication_factor}}
  end


  def handle_call({:lookup, key}, _from, {name, part_raft_map, num_partitions, replication_factor}) do
    assigned_part = KV.Router.get_assigned_part(Map.keys(part_raft_map), key)
    raft_state = Map.get(part_raft_map, assigned_part)
      |> Enum.at(0)
      |> Algorithms.Raft.get_status

    value = raft_state.storage
      |> Storage.Backend.lookup(key)

    {:reply, value, {name, part_raft_map, num_partitions, replication_factor}}
  end



  def write(bucket, keyvalue) do
    GenServer.call(bucket, {:write, keyvalue})
  end


  def lookup(bucket, key) do
    GenServer.call(bucket, {:lookup, key})
  end


  def get_state(bucket) do
    GenServer.call(bucket, :get_state)
  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end




end
