defmodule State do
  defstruct write_cache: nil, write_tick: 0, voted_for: nil, term: 0,
    current: :follower, votes_for_me: 0, total_votes: 0
end
