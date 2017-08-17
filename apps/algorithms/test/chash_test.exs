defmodule Algorithms.ConsistentHashing.Test do
  use ExUnit.Case, async: true

  test "check determinism and basic functionality" do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..10, &("key" <> to_string(&1)))
    partitions = Enum.map(1..6, &("partition" <> to_string(&1)))

    {h_partitions, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(partitions, h_func)
    results = Algorithms.ConsistentHashing.find_many(keys, h_partitions, hash_map, h_func)

    assert ([{"key1", "partition5"}, {"key2", "partition5"},
      {"key3", "partition3"}, {"key8", "partition2"},
      {"key4", "partition2"}, {"key5", "partition2"},
      {"key6", "partition5"}, {"key7", "partition2"},
      {"key9", "partition2"}, {"key10", "partition2"}]
      |> Enum.map(&Enum.member?(results, &1))
      |> Enum.reduce(true,
      fn was_in_list, acc ->
        was_in_list && acc
      end)) == true
  end


  @tag :performance
  test "scale and performance test" do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..100_000, &("key" <> to_string(&1)))
    partitions = Enum.map(1..128_000, &("partition" <> to_string(&1)))

    {h_partitions, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(partitions, h_func)
    time =
      fn -> Algorithms.ConsistentHashing.find_many(keys, h_partitions, hash_map, h_func) end
      |> :timer.tc
      |> elem(0)
      |> Kernel./(1_000_000)

    # Dependent on system; usually less than one
    assert time < 1
  end


end
