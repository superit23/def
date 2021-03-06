defmodule Storage.Ets do
  use GenServer

  ## Init
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    commit_table = :ets.new(Commit, [read_concurrency: true])
    {:ok, commit_table}
  end




  ## GenServer Calls
  def handle_call({:write, keyvalue}, _from, commit_table) do
    success = :ets.insert(commit_table, keyvalue)
    {:reply, success, commit_table}
  end


  def handle_call({:delete, key}, _from, commit_table) do
    success = :ets.delete(commit_table, key)
    {:reply, success, commit_table}
  end


  def handle_call({:lookup, key}, _from, commit_table) do
    value = :ets.lookup(commit_table, key)
    {:reply, value, commit_table}
  end


end
