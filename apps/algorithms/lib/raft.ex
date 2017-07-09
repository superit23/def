defmodule Algorithms.Raft do

  @behaviour :gen_statem
  @election_timeout_min 4_000
  @election_timeout_max 5_000

  @heartbeat_freq 2_000

  ## Public API
  def start_link(commit_storage, cache_storage) do
    :gen_statem.start_link(__MODULE__, {commit_storage, cache_storage}, [])
  end


  def get_status(pid) do
    # :gen_statem.call(:global.whereis_name(to_string(node()) <> ".Raft"), :get_status)
    :gen_statem.call(pid, :get_status)
  end


  def write(pid, {key, value}) do
    write(pid,[{key, value}])
  end

  def write(pid, list) do
    :gen_statem.cast(pid, {:write, list})
  end


  ## Callbacks
  def callback_mode do
    :handle_event_function
  end


  def init({commit_storage, cache_storage}) do
    #write_cache = :ets.new(write_cache_name, [:named_table, read_concurrency: true])
    :global.register_name(to_string(node()) <> ".Raft", self())
    {:ok, :follower, %State{write_cache: cache_storage, storage: commit_storage, write_tick: 0, voted_for: nil, term: 0}, [{:next_event, :cast, :wait}]}
  end


  def terminate(_reason, _state, _data) do
    :void
  end


  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end


  ## Server functions
  def handle_event({:call, from}, :get_status, state, data) do
    cond do
      state == :leader -> {:keep_state, data, [{:reply, from, data}, {:next_event, :cast, :send_entries}]}
      true -> {:keep_state, data, [{:reply, from, data}]}
    end
  end


  ## State functions

  ## Leader

  def handle_event(:cast, :send_entries, :leader, data) do
    data = %{data | current: :leader}
    entries = Storage.Backend.lookup(data.write_cache, data.write_tick)

    ## Always send entries as a type of heartbeat
    for node <- Services.Framework.nodes do
      :gen_statem.cast(:global.whereis_name(to_string(node) <> ".Raft"), {:append_entries, %{id: data.append_tick, entries: entries, leader: self()}})
    end

    data =
      if Enum.count(entries) > 0 do
        %{data | write_tick: data.write_tick + 1, num_confirms: 1}
      else
        data
      end

    {:keep_state, data, @heartbeat_freq}
  end


  def handle_event(:timeout, _time, :leader, data) do
    {:keep_state, data, [{:next_event, :cast, :send_entries}]}
  end


  def handle_event(:cast, :append_entries_confirm, :leader, data) do
    data = %{data | num_confirms: data.num_confirms + 1}

    data =
      if data.num_confirms > Enum.count(Services.Framework.nodes) / 2 do
        Storage.Backend.lookup(data.write_cache, data.append_tick)
          |> Enum.at(0)
          |> elem(1)
          |> Enum.map(&Storage.Backend.write(data.storage, &1))

        for node <- Services.Framework.nodes do
          :gen_statem.cast(:global.whereis_name(to_string(node) <> ".Raft"), {:commit_entries, %{id: data.append_tick}})
        end

        %{data | append_tick: data.append_tick + 1}
      else
        data
      end

    {:keep_state, data, [{:next_event, :cast, :send_entries}]}
  end


  def handle_event(:cast, {:write, key_values}, :leader, data) do
    Storage.Backend.write(data.write_cache, {data.write_tick, key_values})
    {:keep_state, data, [{:next_event, :cast, :send_entries}]}
  end



  ## Candidate

  def handle_event(:cast, :request_vote, :candidate, data) do
    data = %{data | current: :candidate}

    for node <- Services.Framework.nodes do
      :gen_statem.cast(:global.whereis_name(to_string(node) <> ".Raft"), {:receive_vote_req, %{term: data.term, sender: self(), node: to_string(node())}})
    end

    {:keep_state, data}
  end


  def handle_event(:cast, {:vote, %{vote: voted_for_me, term: received_term}}, :candidate, data) do
    data =
      if data.votes_for_me == 0 do
        %{data | votes_for_me: 1}
      else
        data
      end

    data =
      if voted_for_me && received_term == data.term do
        %{data | votes_for_me: data.votes_for_me + 1}
      else
        data
      end

    data =
      if received_term == data.term do
        %{data | total_votes: data.total_votes + 1}
      else
        data
      end

    num_nodes = Enum.count(Services.Framework.nodes) + 1

    cond do
      data.votes_for_me > num_nodes / 2 ->
        data = %{data | votes_for_me: 0, total_votes: 0}
        {:next_state, :leader, data, [{:next_event, :cast, :send_entries}]}
      data.votes_for_me - data.total_votes > num_nodes / 2 ->
        data = %{data | votes_for_me: 0, total_votes: 0}
        {:next_state, :follower, data, [{:next_event, :cast, :wait}]}
      true ->
        {:keep_state, data, @election_timeout_min}
    end


  end


  def handle_event(:timeout, _time, :candidate, data) do
    data = %{data | votes_for_me: 0, total_votes: 0}
    {:next_state, :follower, data,[{:next_event, :cast, :wait}]}
  end


  ## Follower [{:event_timeout, @election_timeout_min, :become_candidate}]
  def handle_event(:cast, :wait, :follower, data) do
    data = %{data | current: :follower}
    {:keep_state, data, @election_timeout_min}
  end


  def handle_event(:cast, {:append_entries, msg}, :follower, data) do
    if msg.entries != nil && Enum.count(msg.entries) > 0 do
      ## Cache waiting for two-phase commit
      #{msg.id, msg.entries}
      Storage.Backend.write(data.write_cache, msg.entries)
      :gen_statem.cast(msg.leader, :append_entries_confirm)
    end
    {:keep_state, data, @election_timeout_min}
  end


  def handle_event(:cast, {:commit_entries, msg}, :follower, data) do
    IO.puts "Committing #{msg.id}"
    #:ets.lookup(data.write_cache, msg.id) |> Backend.commit #[{:event_timeout, @election_timeout_min, :become_candidate}]
    Storage.Backend.lookup(data.write_cache, msg.id)
      |> Enum.at(0)
      |> elem(1)
      |> Enum.map(&Storage.Backend.write(data.storage, &1))

    data = %{data | write_tick: data.write_tick + 1}

    {:keep_state, data, @election_timeout_min}
  end


  def handle_event(:cast, {:receive_vote_req, vote_request}, :follower, data) do
    #IO.puts "Received vote_request from " <> vote_request.node
    ## If new term, reset vote
    data =
      cond do
        data.term < vote_request.term -> %{data | voted_for: nil, term: vote_request.term}
        data.term > vote_request.term ->
          data
        true -> data
      end

    ## Vote only if no current vote for term
    {data, vote} =
      if data.voted_for == nil do
        #state.voted_for = vote_request.sender
        {%{data | voted_for: vote_request.sender}, true}
      else
        {data, false}
      end

    :gen_statem.cast(vote_request.sender, {:vote, %{vote: vote, term: data.term}})
    {:keep_state, data, @election_timeout_min}
  end


  def handle_event(:timeout, _time, :follower, data) do
    {:next_state, :candidate, data, [{:next_event, :cast, :request_vote}]}
  end

end
