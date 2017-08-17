defmodule Algorithms.Swim.Receiver do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    {:ok, {[]}}
  end


  def handle_call({:recv_ping, sender}, _from, {nodes}) do
    IO.puts "Entering :recv_ping"
    nodes = if Enum.member?(nodes, sender) do
      nodes
    else
      [sender] ++ nodes
    end

    {:reply, :ok, {nodes}}
  end

end
