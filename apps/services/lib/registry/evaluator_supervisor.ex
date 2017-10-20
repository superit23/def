defmodule Services.Registry.Local.Evaluator.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Services.Registry.Local.Evaluator, [Services.Registry.Local.Evaluator]),
      supervisor(KV.Partition.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
