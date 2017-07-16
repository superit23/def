defmodule Services.Registry.Mnesia.Test do
  use ExUnit.Case, async: true

  test "all registry functions" do
    Services.Registry.Mnesia.start_link

    assert Services.Registry.Mnesia.whereis_name("me") == nil

    Services.Registry.Mnesia.register_name("me", self())
    assert Services.Registry.Mnesia.whereis_name("me") == self()

    Services.Registry.Mnesia.unregister_name("me")
    assert Services.Registry.Mnesia.whereis_name("me") == nil
  end
end
