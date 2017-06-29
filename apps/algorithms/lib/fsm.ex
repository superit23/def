defmodule FiniteStateMachine do

  def start_link(start_state) do
    Agent.start_link(fn -> {start_state, %{}} end)
  end


  def add_transition({curr_state, transitions}, state, transition) do
    old_transitions = Agent.get(transitions, &Map.get(&1, state))
    new_transitions = Map.put(old_transitions, state, transition)

    Agent.update({curr_state, new_transitions},
      fn {curr_state, transitions} ->
        {curr_state, Map.put(transitions, state, new_transitions)} end)
  end


  def remove_transition({curr_state, transitions}, state, transition) do
    old_transitions = Agent.get(transitions, &Map.get(&1, state))
    {_, new_transitions} = Map.pop(old_transitions, transition)

    Agent.update({curr_state, new_transitions},
      fn {curr_state, transitions} ->
        {curr_state, transitions} end)
  end


  def next({curr_state, transitions}, state, transition) do
    valid_transitions = Agent.get(transitions, &Map.get(&1, state))
    next_state = Map.get(valid_transitions, transition)

    Agent.update({next_state, transitions},
      fn {next_state, transitions} -> {next_state, transitions} end)
  end

end
