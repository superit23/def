defmodule Storage.Ets do
  use GenServer

  ## Init
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    commit_table = :ets.new(Commit, [])
    cache_table = :ets.new(Cache, [])
    {:ok, {commit_table, cache_table}}
  end


  ## Public API
  def write(pid, keyvalue) do
    GenServer.call(pid, {:write_cache, keyvalue})
  end


  def delete(pid, keyvalue) do
    GenServer.call(pid, {:commit, keyvalue})
  end


  def lookup(pid, key) do
    GenServer.call(pid, {:lookup, key})
  end


  ## GenServer Calls
  def handle_call({:write, keyvalue}, _from, {commit_table, cache_table}) do
    success = :ets.insert(cache_table, keyvalue)
    {:reply, success, {commit_table, cache_table}}
  end


  def handle_call({:delete, keyvalue}, _from, {commit_table, cache_table}) do
    success = :ets.delete(commit_table, keyvalue)
    {:reply, success, {commit_table, cache_table}}
  end


  def handle_call({:lookup, key}, _from, {commit_table, cache_table}) do
    value = :ets.lookup(commit_table, key)
    {:reply, value, {commit_table, cache_table}}
  end


end
