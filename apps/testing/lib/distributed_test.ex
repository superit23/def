defmodule Mix.Tasks.Test.Distributed do
  use Mix.Task

  @preferred_cli_env :test
  @recursive true
  @default_count 4

  def run(params) do
    {switches, _, _} = OptionParser.parse(params, [switches: [count :integer]])

    app = Mix.Project.config[:app]
    Application.ensure_started(app)

    Keyword.get(switches, :count, @default_count)
      |> DistributedManager.start()


    # Rebuild the params, but remove count
    params = case Keyword.has_key?(switches, :count) do
      true -> remove_count(params)
      false -> params
    end

    Mix.Tasks.Test.run(params)

    DistributedManager.stop()
  end

  # Initial starting point. Recurse with pattern matching.
  defp remove_count(params, acc \\ [])

  # Out of params -> count wasn't in the list. It was default.
  defp remove_count([], acc), do: :lists.reverse(acc)

  # Head is current `count`, next head is the value.
  # Unreverse the list, and return it all.
  defp remove_count(["--count"|[_num|rem]], acc), do: :lists.reverse(acc) ++ rem

  # Head is not `count`, keep search. Above pattern matching will match
  # when we found it.
  defp remove_count([head|rem], acc), do: remove_count(rem, [head|acc])
end
