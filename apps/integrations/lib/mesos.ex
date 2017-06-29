defmodule Integrations.Mesos do
  use Tesla
  use GenServer

  @moduledoc """
  Integrates with Apache Mesos, a two-level scheduling system
   and resource abstraction layer for distributed systems.
  """

  plug Tesla.Middleware.Headers, %{"User-Agent" => "DEF 0.1 (httpc)"}
  plug Tesla.Middleware.JSON

  ## Init
  def start_link(baseURL \\ "http://leader.mesos:5050") do
    GenServer.start_link(__MODULE__, baseURL, name: Mesos)
  end

  def init(baseURL) do
    {:ok, baseURL}
  end


  ## Public API
  @doc """
  Returns all Mesos frameworks.
  """
  def get_frameworks do
    GenServer.call(Mesos, {:get_frameworks})
  end

  @doc """
  Returns all Mesos tasks.
  """
  def get_tasks do
    GenServer.call(Mesos, {:get_tasks})
  end

  @doc """
  Returns all slaves
  """
  def get_slaves do
    GenServer.call(Mesos, {:get_slaves})
  end


  ## GenServer API
  def handle_call({:get_frameworks}, _from, baseURL) do
    {:reply, get(baseURL <> "/frameworks"), baseURL}
  end

  def handle_call({:get_tasks}, _from, baseURL) do
    {:reply, get(baseURL <> "/tasks"), baseURL}
  end

  def handle_call({:get_slaves}, _from, baseURL) do
    {:reply, get(baseURL <> "/slaves"), baseURL}
  end
end
