defmodule Algorithms.Raft.Test do
  use ExUnit.Case, async: true

  test "single Raft instance converges" do
    {:ok, _framework} = Services.Framework.start_link(%{discovery: [{Discovery.File, nil, %{filepaths: [] }}], services: [], poll_interval: 1000})
    Services.Framework.run
    {:ok, commit} = Storage.Ets.start_link
    {:ok, cache} = Storage.Ets.start_link
    {:ok, raft} = Algorithms.Raft.start_link(commit, cache)

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
