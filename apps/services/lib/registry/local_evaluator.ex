defmodule Services.Registry.Local.Evaluator do
  use GenServer

  ## GenServer controls

  def start_link(table_name) do
    GenServer.start_link(__MODULE__, table_name) #, name: table_name
  end


  def init(table_name) do
    table = :ets.new(table_name, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {table, refs}}
  end


  def stop(server) do
    GenServer.stop(server)
  end


  ## Public API
  @doc """
  Creates a partition for the given table.
  """

  def register_name(registry, name, func) do
    GenServer.call(registry, {:register_name, name, func})
  end

  # def create(registry, partition) do
  #   GenServer.call(registry, {:create, partition, "partition", []})
  # end
  #
  #
  # def create_bucket(registry, bucket, num_partitions, replication_factor) do
  #   GenServer.call(registry, {:create, bucket, "bucket", {num_partitions, replication_factor}})
  # end


  @doc """
  Finds a partition in the given table.
  """
  def lookup!(table, partition) when is_atom(table) do
    case :ets.lookup(table, partition) do
      [{^partition, pid}] -> {:ok, pid}
      [] -> :error
    end
  end


  def lookup_call!(registry, partition) do
    GenServer.call(registry, {:whereis_name, partition})
  end


  ## GenServer calls

  @doc """
  Creates a process locally using a given `func` and registers it under the given `name`.
  """
  def handle_call({:register_name, name, func}, _from, {table, refs}) do
    case lookup!(table, name) do
      {:ok, pid} -> {:reply, pid, {table, refs}}
      :error ->
        {:ok, pid} = func.()

        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(table, {name, pid})

        {:reply, pid, {table, refs}}
      end
  end
  # def handle_call({:create, name, should_register, func}, _from, {table, refs}) do
  #   case lookup!(table, name) do
  #     {:ok, pid} -> {:reply, pid, {table, refs}}
  #     :error ->
  #       {:ok, pid} = func.()
  #
  #       if should_register do
  #         ref = Process.monitor(pid)
  #         refs = Map.put(refs, ref, name)
  #         :ets.insert(table, {name, pid})
  #       end
  #
  #       {:reply, pid, {table, refs}}
  #     end
  # end


  def handle_call({:whereis_name, partition}, _from, {table, refs}) do
    {:reply, lookup!(table, partition), {table, refs}}
  end


  def handle_info({:DOWN, ref, :process, _pid, _reason}, {table, refs}) do
    {partition, refs} = Map.pop(refs, ref)
    :ets.delete(table, partition)
    {:noreply, {table, refs}}
  end


  def handle_info(_msg, state) do
    {:noreply, state}
  end


end
