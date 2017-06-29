defmodule Algorithms.ConsistentHashing do
  @doc """
  Takes in buckets AS AN ERLANG ARRAY, key, hash-map between bucket hashes and buckets,
  and hash function.
  Returns the bucket to which the key belongs.
  """
  def find(key, buckets, hash_map, h_func) do
    find_many([key], buckets, hash_map, h_func)
  end


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


  def prepare_buckets(buckets, h_func) do
    h_buckets = buckets |> Enum.map(&h_func.(&1)) |> Enum.sort
    hash_map = buckets |> Enum.reduce(%{},
      fn bucket, acc ->
        Map.put(acc, h_func.(bucket), bucket)
      end)

    {:array.from_list(h_buckets), hash_map}
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


  defp get_index(buckets, index, key) do
    head = Enum.at(buckets, index)

    cond do
      head == nil -> Enum.at(buckets, 0)
      key > head -> get_index(buckets, index + 1, key)
      key <= head -> head
    end
  end


  def test(n_keys, n_buckets) do
    h_func = fn val -> :erlang.phash2(val) end
    keys = Enum.map(1..n_keys, &("key" <> to_string(&1)))
    buckets = Enum.map(1..n_buckets, &("bucket" <> to_string(&1)))

    {h_buckets, hash_map} = prepare_buckets(buckets, h_func)
    Algorithms.ConsistentHashing.find_many(keys, h_buckets, hash_map, h_func)
  end


end
