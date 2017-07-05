defmodule Storage.Backend do
  @callback start_link(any) :: any
  @callback write(pid, any) :: any
  @callback delete(pid, any) :: any
  @callback lookup(pid, any) :: any
end
