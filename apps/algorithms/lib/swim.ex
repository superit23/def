defmodule Algorithms.Swim do

  @behaviour :gen_statem

  defmacro __using__(_opts) do
    quote do
      import Algorithms.Swim
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


  def join(pid, new_member) do
    :gen_statem.cast(pid, {:join, new_member})
  end


  def get_status(pid) do
    :gen_statem.call(pid, :get_status)
  end


  ## Failure detection

  def handle_event(:timeout, _time, :member, data) do
    {:keep_state, data, [{:next_event, :cast, :ping}]}
  end


  def handle_event(:cast, {:join, new_member}, :member, data) do
    {:keep_state, %{data | members: [new_member] ++ data.members}, [{:next_event, :cast, :ping}]}
  end


  def handle_event(:cast, :wait, :member, data) do
    {:keep_state, data, 500}
  end


  def handle_event({:call, from}, :get_status, :member, data) do
    {:keep_state, data, [{:reply, from, data}, {:next_event, :cast, :wait}]}
  end


  def handle_event(:cast, :ping, :member, data) do
    if Enum.count(data.members) > 0 do

      to_ping = Enum.random(data.members)

      _result = try do
        :gen_statem.call(to_ping, {:recv_ping, self()}, 500)
        #:gen_statem.cast(to_ping, :wait)
      catch
        :exit, _reason ->
          :gen_statem.call(Enum.random(data.members), {:proxy_ping, to_ping}, 500)
      end
      
      :gen_statem.cast(to_ping, :wait)
    end

    data = %{data | counter: data.counter + 1}
    {:keep_state, data, 500}
  end


  def handle_event({:call, from}, {:recv_ping, sender}, :member, data) do
    data = if Enum.member?(data.members, sender) do
      data
    else
      %{data | members: [sender] ++ data.members}
    end
#, {:next_event, :cast, :wait}
    {:keep_state, data, [{:reply, from, :pong}]}
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
