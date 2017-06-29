# defmodule Algorithms.BinaryTree do
#   @moduledoc """
#   Taken from: https://gist.github.com/leighhalliday/2f0db4ce44ba7693744d
#   Binary trees store data in such a way that achieves log(n) reads and log(n) writes.
#   """
#
#   def create(new_value) do
#    %{value: new_value, left: nil, right: nil}
#   end
#
#
#
#   ## Adding nodes
#   def add_node(nil, new_value) do
#    create(new_value)
#   end
#
#   def add_node(%{value: value, left: left, right: right}, new_value) do
#     ## Recursively navigates the tree to find where to put the element
#    if new_value < value do
#      %{value: value, left: add_node(left, new_value), right: right}
#    else
#      %{value: value, left: left, right: add_node(right, new_value)}
#    end
#   end
#
#
#   def delete_node(nil, node) do
#
#   end
#
#   def delete_node(%{value: value, left: left, right: right}, node) do
#     delete_node(%{value: value, left: left, right: right}, nil, node)
#   end
#
#   def delete_node(%{value: value, left: left, right: right}, parent, node) do
#     cond do
#       sval == value -> true
#       sval < value -> delete_node(left, sval)
#       sval > value -> delete_node(right, sval)
#     end
#   end
#
#
#
#   ## Counting nodes
#   def count(nil) do
#    0
#   end
#
#   def count(%{left: left, right: right}) do
#    1 + count(left) + count(right)
#   end
#
#
#
#   ## Reducing nodes
#   def reduce(nil, _f, accumulator) do
#    accumulator
#   end
#
#   def reduce(%{value: value, left: left, right: right}, f, accumulator) do
#    accumulator = reduce(left, f, f.(value, accumulator))
#    reduce(right, f, accumulator)
#   end
#
#
#
#   ## Determine if value exists
#   def exists?(nil, _sval) do
#    false
#   end
#
#   def exists?(%{value: value, left: left, right: right}, sval) do
#    cond do
#      sval == value -> true
#      sval < value -> exists?(left, sval)
#      sval > value -> exists?(right, sval)
#    end
#   end
#
#
#
#   ## Utility functions
#   def to_list(tree) do
#    reduce(tree, (fn (value, accumulator) -> [v | accumulator] end), [])
#   end
#
#   def balance(tree) do
#    to_balance_list(tree) |> Enum.reduce(nil, (fn (x, accumulator) ->
#      add_node accumulator, x
#    end))
#   end
#
#   # [1,2,3,4] becomes [3,2,4,1]
#   # this new list can then create a new
#   # binary tree which is balanced
#   defp to_balance_list(tree) do
#    list = Enum.sort(to_list(tree))
#
#    count = Enum.count(list)
#    half = round(Float.ceil(count / 2))
#
#    la = Enum.reverse(Enum.slice(list, 0, half))
#    lb = Enum.slice(list, half, count - 1)
#
#    zip_merge(lb, la)
#   end
#
#   ## Non binary-tree-related merging behaviour
#   def zip_merge([heada | taila], [headb | tailb]) do
#   [heada] ++ [headb] ++ zip_merge(taila, tailb)
#   end
#
#   def zip_merge([heada | taila], []) do
#   [heada] ++ zip_merge(taila, [])
#   end
#
#   def zip_merge([], [headb | tailb]) do
#   [headb] ++ zip_merge([], tailb)
#   end
#
#   def zip_merge([], []) do
#   []
#   end
# end
