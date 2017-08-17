defmodule Algorithms.CHAnalysis do
  import ExProf.Macro

  def analyze(n_keys, n_partitions) do
    h_func = fn val -> :erlang.phash2(val, 4_294_967_296) end
    keys = Enum.map(1..n_keys, &("key" <> to_string(&1)))
    partitions = Enum.map(1..n_partitions, &("partition" <> to_string(&1)))

    {h_partitions, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(partitions, h_func)

    _ = profile do
      Algorithms.ConsistentHashing.find_many(keys, h_partitions, hash_map, h_func)
    end
    {:ok}

  end

  def sort(n_keys) do
    _ = profile do
      keys = Enum.map(1..n_keys, &(:erlang.phash2("key" <> to_string(&1))))
      keys |> Enum.sort
      :array.from_list(keys)
    end
    {:ok}
  end


  def ets_perf(n_keys) do
    keys = Enum.map(1..n_keys, &{&1, :erlang.phash2("key" <> to_string(&1))})
    table = :ets.new(ETSTable, [:named_table, read_concurrency: true])
    :ets.insert(ETSTable, {1, 124_145_142})
    IO.puts "#{Enum.at(:ets.lookup(ETSTable, 1), 0)}"

    _ = profile do
      keys |> Enum.each(&:ets.insert(table, &1))
    end
    {:ok}
  end

  def map_perf(n_partitions) do
    #keys = Enum.map(1..n_keys, &(:erlang.phash2("key" <> to_string(&1))))

    #partitions = Enum.map(1..n_partitions, &()&1, :erlang.phash2("partition" <> to_string(&1))))

    partition_map = Enum.map(1..n_partitions, &{&1, :erlang.phash2("partition" <> to_string(&1))})
    |> Enum.reduce(%{},
    fn {idx, partition}, acc ->
      Map.put(acc, idx, partition)
    end)

    _ = profile do
      1..n_partitions |> Enum.map(&Map.get(partition_map, &1))
    end
    {:ok}
  end
end
