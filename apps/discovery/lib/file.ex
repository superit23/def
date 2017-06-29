defmodule Discovery.File do

  @behaviour Discovery.Strategy

  def start_link(_args \\ "") do
    {:ok, file} = File.open "/tmp/nodes", [:append]
    IO.binwrite(file, Enum.join([to_string(node()), "\n"], ""))
    File.close file
    {:ok}
  end

  def discover(%{filepaths: filepaths} \\ %{filepaths: []}) do
    filepaths ++ ["/tmp/nodes"]
    |> Stream.map(&File.read(&1))
    |> Enum.map(fn {:ok, text} -> text end)
    |> Enum.flat_map(&String.split(&1, "\n"))
    |> Enum.filter(&(&1 != "" && &1 != to_string(node())))
  end

end
