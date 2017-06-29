defmodule KV.Registry do
  use GenServer

  ## GenServer controls

  def start_link(table_name) do
    GenServer.start_link(__MODULE__, table_name, name: table_name)
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
  Creates a bucket for the given table.
  """
  def create(table, bucket) do
    GenServer.call(table, {:create, bucket})
  end


  @doc """
  Finds a bucket in the given table.
  """
  def lookup!(table, bucket) when is_atom(table) do
    case :ets.lookup(table, bucket) do
      [{^bucket, pid}] -> {:ok, pid}
      [] -> :error
    end
  end


  ## GenServer calls

  def handle_call({:create, bucket}, _from, {table, refs}) do
    case lookup!(table, bucket) do
      {:ok, pid} -> {:reply, pid, {table, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket

        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, bucket)
        :ets.insert(table, {bucket, pid})

        {:reply, pid, {table, refs}}
      end
  end


  def handle_info({:DOWN, ref, :process, _pid, _reason}, {table, refs}) do
    {bucket, refs} = Map.pop(refs, ref)
    :ets.delete(table, bucket)
    {:noreply, {table, refs}}
  end


  def handle_info(_msg, state) do
    {:noreply, state}
  end


end
