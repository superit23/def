defmodule KV.Bucket do
  use GenServer

  def start_link(name, num_partitions, replication_factor, router) do
    GenServer.start_link(__MODULE__,
      {name, num_partitions, replication_factor, router})
  end


  def init({name, num_partitions, replication_factor, router}) do
    partitions = Enum.map(0..num_partitions, fn x ->
        Enum.map(0..replication_factor, fn y ->
          KV.Router.create_partition(router, name <> "_part_" <> to_string(x) <> "_rep_" <> to_string(y)) end) end)

    {:ok, {name, partitions, num_partitions, replication_factor, router}}
  end


  def get_state(bucket) do
    GenServer.call(bucket, :get_state)
  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end




end
