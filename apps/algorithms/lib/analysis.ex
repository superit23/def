defmodule Algorithms.CHAnalysis do
  import ExProf.Macro

  def analyze(n_keys, n_buckets) do
    h_func = fn val -> :erlang.phash2(val, 4294967296) end
    keys = Enum.map(1..n_keys, &("key" <> to_string(&1)))
    buckets = Enum.map(1..n_buckets, &("bucket" <> to_string(&1)))

    {h_buckets, hash_map} = Algorithms.ConsistentHashing.prepare_buckets(buckets, h_func)

    eat = profile do
      Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func)
    end
    {:ok}

  end

  def sort(n_keys) do


    eat = profile do
      keys = Enum.map(1..n_keys, &(:erlang.phash2("key" <> to_string(&1))))
      keys |> Enum.sort
      a_keys = :array.from_list(keys)
    end
    {:ok}
  end


  def ets_perf(n_keys) do
    keys = Enum.map(1..n_keys, &{&1, :erlang.phash2("key" <> to_string(&1))})
    table = :ets.new(ETSTable, [:named_table, read_concurrency: true])
    :ets.insert(ETSTable, {1, 124145142})
    IO.puts "#{Enum.at(:ets.lookup(ETSTable, 1), 0)}"

    eat = profile do
      keys |> Enum.each(&:ets.insert(table, &1))
    end
    {:ok}
  end

  def map_perf(n_buckets) do
    #keys = Enum.map(1..n_keys, &(:erlang.phash2("key" <> to_string(&1))))

    #buckets = Enum.map(1..n_buckets, &()&1, :erlang.phash2("bucket" <> to_string(&1))))

    bucket_map = Enum.map(1..n_buckets, &{&1, :erlang.phash2("bucket" <> to_string(&1))})
    |> Enum.reduce(%{},
    fn {idx, bucket}, acc ->
      Map.put(acc, idx, bucket)
    end)

    eat = profile do
      1..n_buckets |> Enum.map(&Map.get(bucket_map, &1))
    end
    {:ok}
  end
end
