defmodule Storage.Backend do
  # @callback start_link(any) :: any
  # @callback write(pid, any) :: any
  # @callback delete(pid, any) :: any
  # @callback lookup(pid, any) :: any

  ## Public API
  def write(pid, keyvalue) do
    GenServer.call(pid, {:write, keyvalue})
  end


  def delete(pid, key) do
    GenServer.call(pid, {:delete, key})
  end


  def lookup(pid, key) do
    GenServer.call(pid, {:lookup, key})
  end
end
