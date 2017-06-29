defmodule Algorithms.ConsistentHashing.Test do
  use ExUnit.Case, async: true

  test "check determinism and basic functionality" do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..10, &("key" <> to_string(&1)))
    buckets = Enum.map(1..6, &("bucket" <> to_string(&1)))

    {h_buckets, hash_map} = Algorithms.ConsistentHashing.prepare_buckets(buckets, h_func)
    results = Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func)
    assert results ==
      [{"key1", "bucket5"}, {"key2", "bucket5"},
      {"key3", "bucket3"}, {"key8", "bucket2"},
      {"key4", "bucket2"}, {"key5", "bucket2"},
      {"key6", "bucket5"}, {"key7", "bucket2"},
      {"key9", "bucket2"}, {"key10", "bucket2"}]
  end


  test "scale and performance test" do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..100000, &("key" <> to_string(&1)))
    buckets = Enum.map(1..128000, &("bucket" <> to_string(&1)))

    {h_buckets, hash_map} = Algorithms.ConsistentHashing.prepare_buckets(buckets, h_func)
    time =
      fn -> Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func) end
      |> :timer.tc
      |> elem(0)
      |> Kernel./(1_000_000)

    assert time < 1
  end


end
