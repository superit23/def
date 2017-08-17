defmodule KV.Partition.Test do
  use ExUnit.Case, async: true

  test "store values by key" do
    KV.Partition.Supervisor.start_link
    {:ok, pid} = KV.Partition.Supervisor.start_partition

    assert KV.Partition.get(pid, "key") == nil
    assert KV.Partition.put(pid, "key", "value") == :ok
    assert KV.Partition.get(pid, "key") == "value"
    assert KV.Partition.delete(pid, "key") == "value"
    assert KV.Partition.get(pid, "key") == nil
  end

end
