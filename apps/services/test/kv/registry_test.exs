defmodule KV.Registry.Test do
  use ExUnit.Case

  doctest KV.Registry

  setup %{} do
    registry = KV.Registry.Supervisor.start_link
    {:ok, registry: registry}
  end

  test "check ETS storage" do
    assert KV.Registry.lookup!(KV.Registry, "bucket") == :error
    bucket = KV.Registry.create(KV.Registry, "bucket")
    assert KV.Registry.lookup!(KV.Registry, "bucket") == {:ok, bucket}
    assert KV.Bucket.get(bucket, "key") == nil
    assert KV.Bucket.put(bucket, "key", "value") == :ok
  end


  test "removes buckets on exit" do
    KV.Registry.create(KV.Registry, "bucket")
    {:ok, bucket} = KV.Registry.lookup!(KV.Registry, "bucket")
    Agent.stop(bucket)

    _ = KV.Registry.create(KV.Registry, "bogus")
    assert KV.Registry.lookup!(KV.Registry, "bucket") == :error
  end


  test "removes bucket on crash" do
    KV.Registry.create(KV.Registry, "bucket")
    {:ok, bucket} = KV.Registry.lookup!(KV.Registry, "bucket")

    ref = Process.monitor(bucket)
    Process.exit(bucket, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}

    _ = KV.Registry.create(KV.Registry, "bogus")
    assert KV.Registry.lookup!(KV.Registry, "bucket") == :error
  end


end
