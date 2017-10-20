defmodule Services.Registry.Global.Mnesia.Test do
  use ExUnit.Case, async: true

  test "all registry functions" do
    {:ok, pid } = Services.Registry.Global.Mnesia.start_link

    assert Services.Registry.whereis_name(pid, "me") == nil

    Services.Registry.register_name("me", self())
    assert Services.Registry.whereis_name(pid, "me") == self()

    Services.Registry.unregister_name("me")
    assert Services.Registry.whereis_name(pid, "me") == nil
  end
end
