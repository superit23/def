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
    partitions = Enum.map(0..num_partitions, fn x ->
        Enum.map(0..replication_factor, fn y ->
          KV.Router.create_partition(proc_registry, name <> "_part_" <> to_string(x) <> "_rep_" <> to_string(y)) end) end)

    {:reply, :ok, {name, partitions, num_partitions, replication_factor}}
  end


  def get_state(bucket) do
    GenServer.call(bucket, :get_state)
  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end




end
