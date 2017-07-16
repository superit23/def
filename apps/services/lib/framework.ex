defmodule Services.Framework do
  use GenServer
  @moduledoc """
  This service manages the framework as a whole. It registers and monitors
  other services loaded into DEF.
  """

  def start_link(state = %{discovery: _, poll_interval: _, services: _}) do
    GenServer.start_link(__MODULE__, state, name: Services.Framework)
  end


  def init(%{discovery: strategies, poll_interval: poll, services: services}) do
    # Initialize all services and strategies
    for {strategy, init_args, _} <- strategies do
      strategy.start_link(init_args)
    end

    {:ok, %{discovery: strategies, poll_interval: poll, services: services, nodes: [], ticks: 0}}
  end


  def run do
    GenServer.call(Services.Framework, :run)
  end


  def nodes do
    GenServer.call(Services.Framework, :get_nodes)
  end

  def status do
    GenServer.call(Services.Framework, :status)
  end


  defp poll(state) do
    Process.send_after(self(), :discover, state.poll_interval)
  end


  def handle_call(:run, _from, state) do
    # Run discovery
    send(self(), :discover)
    poll(state)

    for {service, init_args} <- state.services do
      service.start_link(init_args)
    end

    {:reply, :ok, state}
  end


  def handle_call(:get_nodes, _from, state) do
    {:reply, state.nodes, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, state.ticks, state}
  end


  def handle_info(:discover, state) do
    discovered_nodes =
       state.discovery
       |> Enum.map(
       fn {strategy, _, arguments} ->
         strategy.discover(arguments)
       end)
       |> List.flatten
       |> Enum.uniq
       |> Enum.filter(&(&1 != to_string(node())))
       |> Enum.map(&(String.to_atom(&1)))

    discovered_nodes -- state.nodes
      |> Enum.each(&Node.connect &1)

    poll(state)
    {:noreply, %{state | nodes: Enum.uniq(discovered_nodes ++ state.nodes), ticks: state.ticks + 1}}
  end

end
