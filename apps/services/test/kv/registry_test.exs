defmodule Services.Registry.Local.Evaluator.Test do
  use ExUnit.Case

  doctest Services.Registry.Local.Evaluator

  setup do
    {:ok, registry_sup} = Services.Registry.Local.Evaluator.Supervisor.start_link
    registry = Supervisor.which_children(registry_sup) |> Enum.at(1) |> elem(1)
    %{registry: registry}
  end

  test "check ETS storage", %{registry: registry} do
    assert Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket") == :error

    bucket = Services.Registry.Local.Evaluator.register_name(registry, "bucket", fn ->
      KV.Partition.Supervisor.start_partition
    end)

    assert Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket") == {:ok, bucket}
    assert KV.Partition.get(bucket, "key") == nil
    assert KV.Partition.put(bucket, "key", "value") == :ok
  end


  test "removes buckets on exit", %{registry: registry} do
    _ = Services.Registry.Local.Evaluator.register_name(registry, "bucket", fn ->
          KV.Partition.Supervisor.start_partition
        end)

    {:ok, bucket} = Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket")
    Agent.stop(bucket)

    _ = Services.Registry.Local.Evaluator.register_name(registry, "bogus", fn ->
          KV.Partition.Supervisor.start_partition
        end)

    assert Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket") == :error
  end


  test "removes bucket on crash", %{registry: registry} do
    _ = Services.Registry.Local.Evaluator.register_name(registry, "bucket", fn ->
          KV.Partition.Supervisor.start_partition
        end)

    {:ok, bucket} = Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket")

    ref = Process.monitor(bucket)
    Process.exit(bucket, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}

    _ = Services.Registry.Local.Evaluator.register_name(registry, "bogus", fn ->
          KV.Partition.Supervisor.start_partition
        end)

    assert Services.Registry.Local.Evaluator.lookup_call!(registry, "bucket") == :error
  end


end
