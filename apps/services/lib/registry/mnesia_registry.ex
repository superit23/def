defmodule Services.Registry.Global.Mnesia do

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    :mnesia.create_schema([node()] ++ Services.Framework.nodes)
    :mnesia.start()
    :mnesia.create_table(ProcRegistry, [attributes: [:name, :pid]])
    {:ok, {}}
  end


  def handle_call({:whereis_name, name}, _from, {}) do
    {:atomic, [record]} = :mnesia.transaction(fn ->
      :mnesia.read({ProcRegistry, name})
    end)
    {:reply, elem(record, 2), {}}
  end


  def handle_call({:register_name, name, pid}, _from, {}) do
    :mnesia.transaction(fn ->
      :mnesia.write({ProcRegistry, name, pid})
    end)
    {:reply, true, {}}
  end


  def handle_call({:unregister_name, name}, _from, {}) do
    :mnesia.transaction(fn ->
      :mnesia.delete({ProcRegistry, name})
    end)
    {:reply, true, {}}
  end

end
