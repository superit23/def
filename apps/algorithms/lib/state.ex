defmodule State do
  defstruct write_cache: nil, storage: nil, write_tick: 0, voted_for: nil,
    term: 0, current: :follower, votes_for_me: 0, total_votes: 0, num_confirms: 0,
    append_tick: 0, leader: nil, group_name: nil
end
