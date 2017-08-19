defmodule Storage.Partition do
  use GenServer

  def start_link(part_pid) do
    GenServer.start_link(__MODULE__, part_pid, [])
  end


  def init(part_pid) do
    {:ok, part_pid}
  end


  ## GenServer Calls
  def handle_call({:write, {key, value}}, _from, part_pid) do
    :ok = KV.Partition.put(part_pid, key, value)
    {:reply, true, part_pid}
  end


  def handle_call({:delete, key}, _from, part_pid) do
    _value =  KV.Partition.delete(part_pid, key)
    {:reply, true, part_pid}
  end


  def handle_call({:lookup, key}, _from, part_pid) do
    value = KV.Partition.get(part_pid, key)
    {:reply, value, part_pid}
  end

end
