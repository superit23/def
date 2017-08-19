defmodule KV.Bucket do
  use GenServer

  def start_link(name, num_partitions, replication_factor) do
    GenServer.start_link(__MODULE__,
      {name, num_partitions, replication_factor})
  end


  def init({name, num_partitions, replication_factor}) do
    {:ok, {name, [], num_partitions, replication_factor}}
  end


  def init_partitions(bucket, proc_registry) do
    GenServer.call(bucket, {:init_partitions, proc_registry})
  end


  def handle_call({:init_partitions, proc_registry}, _from, {name, [], num_partitions, replication_factor}) do
    partitions = Enum.map(0..num_partitions, fn part_num ->
        Enum.map(0..replication_factor, fn rep_num ->
          part_string = name <> "_part_" <> to_string(part_num)
          {assigned_node, pid} = KV.Router.create_partition(proc_registry, part_string <> "_rep_" <> to_string(rep_num))

          ## TODO: Raft and storage instances should be on same node as partition
          KV.Router.create_raft(proc_registry, part_string, assigned_node, pid)
         end)
       end)

    {:reply, :ok, {name, partitions, num_partitions, replication_factor}}
  end


  def get_state(bucket) do
    GenServer.call(bucket, :get_state)
  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end




end
