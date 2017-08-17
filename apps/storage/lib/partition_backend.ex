defmodule Storage.Partition do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    {:ok, {KV.Registry.create()}}
  end


end
