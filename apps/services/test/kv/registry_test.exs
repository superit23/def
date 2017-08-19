defmodule KV.Registry.Test do
  use ExUnit.Case

  doctest KV.Registry

  setup do
    {:ok, registry_sup} = KV.Registry.Supervisor.start_link
    registry = Supervisor.which_children(registry_sup) |> Enum.at(1) |> elem(1)
    %{registry: registry}
  end

  test "check ETS storage", %{registry: registry} do
    assert KV.Registry.lookup_call!(registry, "bucket") == :error
    #bucket = KV.Registry.create(KV.Registry, "bucket")
    bucket = KV.Registry.create(registry, "bucket", true, fn ->
      KV.Partition.Supervisor.start_partition
    end)

    assert KV.Registry.lookup_call!(registry, "bucket") == {:ok, bucket}
    assert KV.Partition.get(bucket, "key") == nil
    assert KV.Partition.put(bucket, "key", "value") == :ok
  end


  test "removes buckets on exit", %{registry: registry} do
    _ = KV.Registry.create(registry, "bucket", true, fn ->
          KV.Partition.Supervisor.start_partition
        end)

    {:ok, bucket} = KV.Registry.lookup_call!(registry, "bucket")
    Agent.stop(bucket)

    _ = KV.Registry.create(registry, "bogus", true, fn ->
          KV.Partition.Supervisor.start_partition
        end)

    assert KV.Registry.lookup_call!(registry, "bucket") == :error
  end


  test "removes bucket on crash", %{registry: registry} do
    _ = KV.Registry.create(registry, "bucket", true, fn ->
          KV.Partition.Supervisor.start_partition
        end)

    {:ok, bucket} = KV.Registry.lookup_call!(registry, "bucket")

    ref = Process.monitor(bucket)
    Process.exit(bucket, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}

    _ = KV.Registry.create(registry, "bogus", true, fn ->
          KV.Partition.Supervisor.start_partition
        end)

    assert KV.Registry.lookup_call!(registry, "bucket") == :error
  end


end
