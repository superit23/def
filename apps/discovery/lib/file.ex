defmodule Discovery.File do

  @moduledoc """
  Taking in a list of `filepaths`, this discover strategy will assume each line
  is a node.
  """

  @behaviour Discovery.Strategy

  @doc """
  Initializes the discovery mechanism by writing to '/tmp/nodes'. Does not
  take any arguments.
  """
  def start_link(_args \\ "") do
    {:ok, file} = File.open "/tmp/nodes", [:append]
    IO.binwrite(file, Enum.join([to_string(node()), "\n"], ""))
    File.close file
    {:ok}
  end

  @doc """
  Reads the files from the given `filepaths` along with '/tmp/nodes'. Arguments
  optional.
  """
  def discover(%{filepaths: filepaths} \\ %{filepaths: []}) do
    filepaths ++ ["/tmp/nodes"]
    |> Stream.map(&File.read(&1))
    |> Enum.map(fn {:ok, text} -> text end)
    |> Enum.flat_map(&String.split(&1, "\n"))
    |> Enum.filter(&(&1 != "" && &1 != to_string(node())))
  end

end
