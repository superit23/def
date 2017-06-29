defmodule State do
  defstruct write_cache: nil, write_tick: 0, voted_for: nil, term: 0, state_string: "follower"
end
