defmodule Integrations.Marathon do
  use Tesla
  use GenServer

  @moduledoc """
  Integrates with Mesospehre Marathon, a Mesos metaframework for scheduling long-running services.
  """

  plug Tesla.Middleware.Headers, %{"User-Agent" => "DEF 0.1 (httpc)"}
  plug Tesla.Middleware.JSON

  ## Init
  @doc "Initializes the module and sets the API URL."
  def start_link(baseURL \\ "http://marathon.mesos:8080/v2") do
    GenServer.start_link(__MODULE__, baseURL, name: Marathon)
  end

  def init(baseURL) do
    {:ok, baseURL}
  end


  ## Public API
  @doc """
  If `app` is specified, returns Marathon configuration of `app`.
  Otherwise, it returns the configuration of all apps.
  """
  def get_apps(app \\ "") do
    GenServer.call(Marathon, {:get_apps, app})
  end

  @doc """
  If `task` is specified, returns Marathon configuration of `task` for the given `app`.
  Otherwise, it returns the configuration of all tasks for `app`.
  """
  def get_tasks(app, task \\ "") do
    GenServer.call(Marathon, {:get_tasks, app, task})
  end


  ## GenServer API
  def handle_call({:get_apps, app}, _from, baseURL) do
    {:reply, get(baseURL <> "/apps/" <> app), baseURL}
  end

  def handle_call({:get_tasks, app, task}, _from, baseURL) do
    {:reply, get(baseURL <> "/apps/" <> app <> "/tasks" <> task), baseURL}
  end
end
