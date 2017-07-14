defmodule Testing.DistributedManager do

  @moduledoc """
  Basically copied from sscheider1207/distributed_test.
  """

  def start(num_nodes) do
    spawn_master()
    num_nodes |> spawn_slaves()
  end


  def stop do
    Node.list()
    |> Enum.map(&:slave.stop/1)
    :net_kernel.stop()
  end


  def spawn_master do
    :net_kernel.start([:"master@127.0.0.1"])
    :erl_boot_server.start([])

    {:ok, ip} = :inet.parse_ipv4_address(~c"127.0.0.1")
    :erl_boot_server.add_slave(ip)
  end


  def spawn_slaves(num_nodes) do
    1..num_nodes
    |> Enum.map(fn idx -> ~c"slave#{idx}@127.0.0.1" end)
    |> Enum.map(&Task.async(fn -> spawn_slave(&1) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end


  defp spawn_slave(node_host) do
    {:ok, node} = :slave.start(~c"127.0.0.1", node_name(node_host),
      ~c"-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}")

    :rpc.block_call(node, :code, :add_paths, [:code.get_path()])

    for {app_name, _, _} <- Application.loaded_applications do
      for {key, value} <- Application.get_all_env(app_name) do
        :rpc.block_call(node, Application, :put_env, [app_name, key, value])
      end
    end

    :rpc.block_call(node, Application, :ensure_all_started, [:mix])
    :rpc.block_call(node, Mix, :env, [Mix.env()])

    for {app_name, _, _} <- Application.loaded_applications do
      :rpc.block_call(node, Application, :ensure_all_started, [app_name])
    end

    {:ok, node}
  end


  defp node_name(node_host) do
    node_host
    |> to_string()
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom()
  end
end
