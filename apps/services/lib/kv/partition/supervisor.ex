defmodule KV.Partition.Supervisor do
  use Supervisor

  @name KV.Partition.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end


  def init(:ok) do
    children = [
      worker(KV.Partition, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end


  def start_partition do
    Supervisor.start_child(@name, [])
  end
end
