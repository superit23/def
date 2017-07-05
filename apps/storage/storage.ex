defmodule Storage do
  @callback write_to_cache(any) :: any
  @callback commit(any) :: any
  @callback lookup(any) :: any
end
