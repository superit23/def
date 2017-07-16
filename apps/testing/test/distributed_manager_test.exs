defmodule Testing.DistributedManager.Test do
  use ExUnit.Case, async: true

  @tag :nondistributed
  test "nodes can be started and stopped" do
    count = 5
    Testing.DistributedManager.start(count)
    assert length(Node.list()) == count

    Testing.DistributedManager.stop()
    assert length(Node.list()) == 0
  end
end
