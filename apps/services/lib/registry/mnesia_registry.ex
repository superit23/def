defmodule Services.Registry.Mnesia do

  def start_link do
    :mnesia.create_schema(List.flatten([node(), Services.Framework.nodes]))
    :mnesia.start()
    :mnesia.create_table(ProcRegistry, [attributes: [:name, :pid]])
  end


  def whereis_name(name) do
    {:atomic, [record]} = :mnesia.transaction(fn ->
      :mnesia.read({ProcRegistry, name})
    end)
    elem(record, 2)
  end


  def register_name(name, pid) do
    :mnesia.transaction(fn ->
      :mnesia.write({ProcRegistry, name, pid})
    end)
  end


  def unregister_name(name) do
    :mnesia.transaction(fn ->
      :mnesia.delete({ProcRegistry, name})
    end)
  end



end
