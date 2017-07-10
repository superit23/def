defmodule Discovery.Multicast do
  use GenServer

  @moduledoc """
  Uses multicast to discover other DEF nodes in the network. To reduce storming,
  the nodes reply to its unicast address.
  """

  @behaviour Discovery.Strategy

  @ucast_port 50_000
  @mcast_port 49_999
  @mcast_group {224,1,1,1}

  @doc """
  Initializes the discovery mechanism. Does not take any arguments.
  """
  def start_link(_args \\ "") do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    udp_options = [
     :binary,
     active:          10,
     add_membership:  {@mcast_group, {0,0,0,0}},
     multicast_if:    {0,0,0,0},
     multicast_loop:  true,
     multicast_ttl:   2,
     reuseaddr:       true
   ]

   {:ok, _socket} = :gen_udp.open(@mcast_port, udp_options)
  end

  @doc """
  Runs the discovery mechanism. Does not take any arguments.
  """
  def discover(_args \\ %{}) do
    udp_options = [:binary, reuseaddr: true]
    {:ok, send_sock} = :gen_udp.open(0, udp_options)
    {:ok, recv_sock} = :gen_udp.open(@ucast_port, udp_options ++ [active: false])

    results = Task.yield_many(
      [
        Task.async(fn -> :gen_udp.recv(recv_sock, 0) end),
        Task.async(fn -> :gen_udp.send(send_sock, @mcast_group, @mcast_port, to_string(node())) end)
      ], 5000)

    :gen_udp.close(send_sock)
    :gen_udp.close(recv_sock)

    to_return =
      for {:ok, {_ip, _port, data}} <- results do
        data
      end

    to_return
  end


  def handle_info({:udp, socket, ip, port, data}, state) do
    # when we popped one message we allow one more to be buffered
    :inet.setopts(socket, [active: 1])
    IO.puts "in listener: #{inspect {ip, port, data}}!"

    udp_options = [:binary, reuseaddr: true]

    ## We got this from multicast:
    ## we need to respond to the request.
    if ip == @mcast_group do

      ## Here, data is the requesters IP
      ip = String.split(data, ".").to_tuple
      {:ok, sock} = :gen_udp.open(0, udp_options)
      :gen_udp.send(sock, ip, @ucast_port, to_string(node()))
      :gen_udp.close(sock)
    end

    {:noreply, state}
  end


end
