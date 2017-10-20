defmodule Algorithms.Swim.Sender do
  @behaviour :gen_statem

  @doc """
  BOTH NODES
  {:ok, _framework} = Services.Framework.start_link(
   %{discovery: [{Discovery.Nop, nil, %{nodes: ["foo@kali",
   "bar@kali"] }}],
   services: [], poll_interval: 500})
  Services.Framework.run
  {:ok, mnesia} = Services.Registry.Global.Mnesia.start_link
  {:ok, swim} = Algorithms.Swim.Sender.start_link
  {:ok, recv} = Algorithms.Swim.Receiver.start_link

  NODE A
  Services.Registry.register_name(mnesia, "barswim", recv)

  NODE B
  barswim = Services.Registry.whereis_name(mnesia, "barswim")
  Algorithms.Swim.join(swim, barswim)
  """

  defmacro __using__(_opts) do
    quote do
      import Algorithms.Swim.Sender
    end
  end


  def start_link do
    :gen_statem.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    {:ok, :member, %{members: [], counter: 0}, [{:next_event, :cast, :ping}]}
  end


  def terminate(_reason, _state, _data) do
    :void
  end


  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end


  def callback_mode do
    :handle_event_function
  end

  def handle_event(:timeout, _time, :member, data) do
    IO.puts "Entering :timeout"
    {:keep_state, data, [{:next_event, :cast, :ping}]}
  end


  def handle_event(:cast, {:join, new_member}, :member, data) do
    {:keep_state, %{data | members: [new_member] ++ data.members}, [{:next_event, :cast, :ping}]}
  end


  def handle_event(:cast, :wait, :member, data) do
    IO.puts "Entering :wait"
    {:keep_state, data, 500}
  end


  def handle_event({:call, from}, :get_status, :member, data) do
    {:keep_state, data, [{:reply, from, data}, {:next_event, :cast, :wait}]}
  end


  def handle_event(:cast, :ping, :member, data) do
    IO.puts "Entering :ping"
    if Enum.count(data.members) > 0 do

      to_ping = Enum.random(data.members)

      _result = try do
        GenServer.call(to_ping, {:recv_ping, self()}, 500)
        #:gen_statem.cast(to_ping, :wait)
      catch
        :exit, _reason ->
          :gen_statem.call(Enum.random(data.members), {:proxy_ping, to_ping}, 500)
      end

      #:gen_statem.cast(to_ping, :wait)
    end

    data = %{data | counter: data.counter + 1}
    {:keep_state, data, 500}
  end





  def handle_event({:call, from}, {:proxy_ping, to_ping}, :member, data) do
    result = try do
      :gen_statem.call(to_ping, :recv_ping, 500)
    rescue
      _exception in TimeoutError ->
        {:nack}
    end
    {:keep_state, data, 500, [{:reply, from, result}]}
  end
end
