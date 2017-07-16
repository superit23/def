defmodule Algorithms.Raft.Test do
  use ExUnit.Case, async: true

  @compile {:inline, run_raft: 0}
  def run_raft do
    {:ok, _framework} = Services.Framework.start_link(
      %{discovery: [{Discovery.Nop, nil, %{nodes: ["master@127.0.0.1",
      "slave1@127.0.0.1", "slave2@127.0.0.1",
      "slave3@127.0.0.1", "slave4@127.0.0.1"] }}],
      services: [], poll_interval: 500})

    Services.Framework.run
    {:ok, commit} = Storage.Ets.start_link
    {:ok, cache} = Storage.Ets.start_link
    {:ok, raft} = Algorithms.Raft.start_link(commit, cache)
    raft
  end

  @tag :distributed
  test "show all Raft processes exist" do
    run_raft()

    for node <- Services.Framework.nodes do
      # pid = Node.spawn_link(node, fn ->
      #   run_raft()
      #   # :timer.sleep(30_000)
      #   receive do
      #     {:ok, msg} -> msg
      #   end
      #  end)

      :rpc.call(node, Algorithms.Raft.Test, :run_raft, [])

      #:timer.sleep(1000)
      curr_raft = :global.whereis_name(to_string(node) <> ".Raft")
      assert Algorithms.Raft.get_status(curr_raft).term == 0
    end
  end


  test "single Raft instance converges" do
    raft = run_raft()
    :timer.sleep(3_250)

    assert Algorithms.Raft.get_status(raft).current == :leader
  end


  @tag :distributed
  test "arbitrary number of Raft instances converge" do
    #{:ok, _framework} = Services.Framework.start_link(%{discovery: [{Discovery.File, nil, %{filepaths: [] }}], services: [], poll_interval: 500})
    {:ok, _framework} = Services.Framework.start_link(%{discovery: [{Discovery.Nop, nil, %{nodes: ["slave1@127.0.0.1", "slave2@127.0.0.1", "slave3@127.0.0.1"] }}], services: [], poll_interval: 500})
    Services.Framework.run
    {:ok, commit} = Storage.Ets.start_link
    {:ok, cache} = Storage.Ets.start_link
    {:ok, raft} = Algorithms.Raft.start_link(commit, cache)

    :timer.sleep(3_250)

    Algorithms.Raft.write(raft, {"key01", "value01"})
    Algorithms.Raft.write(raft, [{"key03", "value03"}, {"key04", "value04"}])

    :timer.sleep(50)

    assert Storage.Backend.lookup(commit, "key01") == {"key01", "value01"}
    assert Storage.Backend.lookup(commit, "key04") == {"key04", "value04"}
    assert Storage.Backend.lookup(commit, "key03") == {"key03", "value03"}
  end


end
