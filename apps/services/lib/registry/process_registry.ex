defmodule Services.Registry do

  def whereis_name(server, name) do
    GenServer.call(server, {:whereis_name, name})
  end


  def register_name(server, name, pid) do
    GenServer.call(server, {:register_name, name, pid})
  end


  def unregister_name(server, name) do
    GenServer.call(server, {:unregister_name, name})
  end
end
