defmodule KV.Bucket.Test do
  use ExUnit.Case, async: true

  test "store values by key" do
    KV.Bucket.Supervisor.start_link
    {:ok, pid} = KV.Bucket.Supervisor.start_bucket

    assert KV.Bucket.get(pid, "key") == nil
    assert KV.Bucket.put(pid, "key", "value") == :ok
    assert KV.Bucket.get(pid, "key") == "value"
    assert KV.Bucket.delete(pid, "key") == "value"
    assert KV.Bucket.get(pid, "key") == nil
  end

end
