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

  #@behaviour :gen_fsm
  @table_name WriteCacheNG

  def start_link do
    #name: via_tuple("1")
    #GenServer.start_link(__MODULE__, :ok, name: RNG)
    init(:ok)
  end

  # defp via_tuple(node_name) do
  #   {:via, :gproc, {:n, 1, {:raft, node_name}}}
  # end

  def init(:ok) do
    write_cache = :ets.new(@table_name, [:named_table, read_concurrency: true])
    :global.register_name(to_string(node()) <> ".Raft", self())
    follower(%State{write_cache: write_cache, write_tick: 0, voted_for: nil, term: 0})
  end



  def follower(state) do
    IO.puts "follower"
    state = %{state | state_string: "follower"}
    receive do
      ## Receive heartbeat/append_entries
      {:append_entries, msg} ->
        if msg.entries != nil && Enum.count(msg.entries) > 0 do
          ## Cache waiting for two-phase commit
          IO.puts "Appending #{msg.entries}"
          :ets.insert(state.write_cache, {msg.id, msg.entries})
        end

      ## Leader tells us to commit
      {:commit_entries, msg} ->
        IO.puts "Committing #{msg.id}"
        :ets.lookup(state.write_cache, msg.id) |> Backend.commit

      ## Getting a Request Vote message will naturally reset the election timeout
      {:request_vote, vote_request} ->
        IO.puts "Received vote_request from " <> vote_request.node
        ## If new term, reset vote
        state =
          cond do
            state.term < vote_request.term -> %{state | voted_for: nil, term: vote_request.term}
            state.term > vote_request.term -> send vote_request.sender, {:vote, false}
            true -> state
          end

        ## Vote only if no current vote for term
        {state, vote} =
          if state.voted_for == nil do
            #state.voted_for = vote_request.sender
            {%{state | voted_for: vote_request.sender}, true}
          else
            {state, false}
          end

        send vote_request.sender, {:vote, %{vote: vote, term: state.term}}
    after
      ## No response from leader/candidate (election timeout)
      5_000 -> candidate(%{state | term: state.term + 1})
    end

    follower(state)
  end


  def candidate(state) do
    IO.puts "candidate"
    state = %{state | state_string: "candidate"}
    ## Wait random time between 150-300ms
    :timer.sleep(150 + :rand.uniform(150))

    ## Vote for self
    votes_for_me = 1
    votes_for_others = 0

    if Enum.count(Node.list) == 0 do
      leader(state)
    end

    for node <- Node.list do
      send :global.whereis_name(to_string(node) <> ".Raft"), {:request_vote, %{term: state.term, sender: self(), node: to_string(node())}}
    end

    receive do
      {:vote, %{vote: voted_for_me, term: received_term}} ->

        votes_for_me =
          if voted_for_me && received_term == state.term do
            votes_for_me + 1
          else
            votes_for_me
          end

        votes_for_others =
          if !voted_for_me do
            votes_for_others = votes_for_others + 1
          else
            votes_for_others
          end

        num_nodes = Enum.count(Node.list) + 1

        ## Lost the election; become follower
        if votes_for_others > num_nodes / 2 do
          follower(state)
        end

        ## Won the election; become leader
        if votes_for_me > num_nodes / 2 do
          leader(state)
        end
      after
        ## Timed out; possible split vote or node failure
        5_000 -> follower(state)
    end

    candidate(state)
  end


  def leader(state) do
    IO.puts Enum.count(Node.list)
    state = %{state | state_string: "leader"}
    :timer.sleep(500)
    entries = :ets.lookup(state.write_cache, state.write_tick)

    ## Always send entries as a type of heartbeat
    for node <- Node.list do
      send :global.whereis_name(to_string(node) <> ".Raft"), {:append_entries, %{id: state.write_tick, entries: entries}}
    end

    state =
      if Enum.count(entries) > 0 do
        %{state | write_tick: state.write_tick + 1}
      else
        state
      end

    leader(state)
  end

end
