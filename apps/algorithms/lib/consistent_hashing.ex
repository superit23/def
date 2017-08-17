defmodule Algorithms.ConsistentHashing do
  @moduledoc """
  Implements the consistent hashing algorithm using an arbitrary hashing function.
  Consistent hashing is used to deterministically map keys to partitions without
  global knowledge.

  ## Examples

    iex> h_func = fn val -> :erlang.phash2(val) end
    <...

    iex> keys = Enum.map(1..10, &("key" <> to_string(&1)))
    ["key1", "key2",...

    iex> buckets = Enum.map(1..6, &("bucket" <> to_string(&1)))
    ["bucket1", "bucket2",...

    iex> {h_buckets, hash_map} = Algorithms.ConsistentHashing.prepare_partitions(buckets, h_func)
    {{:array, 6, 10,...

    iex> Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func)
    [{"key1", "bucket5"}, {"key2", "bucket5"},
    {"key3", "bucket3"}, {"key8", "bucket2"},
    {"key4", "bucket2"}, {"key5", "bucket2"},
    {"key6", "bucket5"}, {"key7", "bucket2"},
    {"key9", "bucket2"}, {"key10", "bucket2"}]

  """

  @doc """
  Takes in buckets AS AN ERLANG ARRAY, key, hash-map between bucket hashes and buckets,
  and hash function.
  Returns a key-bucket tuple.
  """
  def find(key, buckets, hash_map, h_func) do
    find_many([key], buckets, hash_map, h_func)
  end

  @doc """
  Takes in buckets AS AN ERLANG ARRAY, keys, hash-map between bucket hashes and buckets,
  and hash function.
  Returns a list of key-bucket tuples.
  """
  def find_many(keys, h_buckets, hash_map, h_func) do
    size = h_buckets.size()
    last_bucket = h_buckets.get(size - 1)

    keys
     |> Flow.from_enumerable()
     |> Flow.partition()
     |> Flow.map(&{&1, binary_search(h_buckets, h_func.(&1), size, last_bucket)})
     |> Flow.map(&{elem(&1, 0), Map.get(hash_map, elem(&1, 1))})
     |> Enum.to_list()

  end

  @doc """
  Using the supplied buckets and hash function, creates a hash map,
  sorts the buckets, and returns them as an Erlang array.
  """
  def prepare_partitions(partitions, h_func) do
    h_partitions = partitions |> Enum.map(&h_func.(&1)) |> Enum.sort
    hash_map = partitions |> Enum.reduce(%{},
      fn partition, acc ->
        Map.put(acc, h_func.(partition), partition)
      end)

    {:array.from_list(h_partitions), hash_map}
  end



  defp binary_search(h_buckets, key, num_buckets, last_bucket) do
    cond do
      key > last_bucket -> h_buckets.get(0)
      true -> get_bucket_bs(h_buckets, 0, num_buckets, key)
    end
  end


  defp get_bucket_bs(h_buckets, min, max, key) do
    mid = div(min + max, 2)
    bucket_val = h_buckets.get(mid)

    cond do
      min >= max ->
        if key > bucket_val do
          h_buckets.get(mid + 1)
        else
          bucket_val
        end

      key > bucket_val -> get_bucket_bs(h_buckets, mid + 1, max, key)
      key < bucket_val -> get_bucket_bs(h_buckets, min, mid - 1, key)
      true -> bucket_val
    end
  end


  @doc """
  Simple testing functionality. Uses :erlang.phash2/2.
  Takes in number of keys and number of buckets.
  """
  def test(n_keys, n_buckets) do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..n_keys, &("key" <> to_string(&1)))
    buckets = Enum.map(1..n_buckets, &("bucket" <> to_string(&1)))

    {h_buckets, hash_map} = prepare_partitions(buckets, h_func)
    Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func)
  end


end
