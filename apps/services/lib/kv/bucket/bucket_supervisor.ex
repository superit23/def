defmodule KV.Bucket.Supervisor do
  use Supervisor

  @name KV.Bucket.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end


  def init(:ok) do
    children = [
      worker(KV.Bucket, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end


  def start_bucket(name, num_partitions, replication_factor) do
    Supervisor.start_child(@name, [name, num_partitions, replication_factor])
  end
end
