defmodule KV.Partition do

  def start_link do
    Agent.start_link(fn -> %{} end)
  end


  def get(partition, key) do
    Agent.get(partition, &Map.get(&1, key))
  end


  def put(partition, key, value) do
    Agent.update(partition, &Map.put(&1, key, value))
  end


  def delete(partition, key) do
    Agent.get_and_update(partition, &Map.pop(&1, key))
  end


end
