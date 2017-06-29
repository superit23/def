defmodule Algorithms.Raft do
  ## States:
  ## Follower
  ## Candidate
  ## Leader

  ## LEADER ELECTION
  ## All start in Follower
  ## If Followers don't hear from leader, they become a Candidate
  ##  -> Election timeout randomized between 150ms and 300ms
  ## Candidate requests votes from other nodes (votes for itself)
  ## Nodes reply with votes (only votes for first candidate)
  ## After a vote, each node resets its election timeout
  ## Candidate becomes leader if has majority
  ## Leader sends AppendEntries as heartbeat
  ## Election term continues until a follower stops receiving heartbeats
  ##  and becomes a Candidate
  ## Higher election term wins in case of split


  ## COMMITTING/REPLICATION
  ## All changes go through leader
  ## Each change is added as an entry in the node's logger
  ## Entry remains uncommitted
  ## Leader replicates to other nodes
  ## Leader waits until a majority have written the entry
  ## Entry becomes committed on leader
  ## Leader notifies followers it has been committed
  ## They commit as well

  @behaviour :gen_fsm

  def start_link(name, servers) do
    :gen_fsm.start_link(__MODULE__, :ok, [])
  end


  def init(:ok) do
    {:ok, :follower_state, {}}
  end


  def candidate(pid) do
    :gen_fsm.send_event(pid, :candidate)
  end

  def follower(pid) do
    :gen_fsm.send_event(pid, :follower)
  end

  def leader(pid) do
    :gen_fsm.send_event(pid, :leader)
  end


  def follower_state(:follower, state) do
    IO.puts "Follower state!"
    receive do
      {:request_vote, msg} -> msg
      {:append_entries, msg} -> msg
    after
      5_000 -> {:next_state, :candidate_state, state}
    end
  end


  def candidate_state(:candidate, state) do
    IO.puts "Candidate state!"
    {:next_state, :leader_state, state}
  end


  def leader_state(:leader, state) do
    IO.puts "Leader state!"
    {:next_state, :leader_state, state}
  end

   def handle_event(_event, state_name, state) do
     {:next_state, state_name, state}
   end

  #  def handle_sync_event(_event, _from, state_name, state) do
  #    {:next_state, state_name, state}
  #  end

  #  def handle_info(:stop, _state_name, state) do
  #    {:stop, :normal, state};
  #  end
   #
  #  def handle_info(_Info, state_name, state) do
  #    {:next_state, state_name, state}
  #  end
   #
  #  def terminate(reason, _state_name, _state) do
  #    reason
  #  end

end
