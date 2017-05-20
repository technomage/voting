defmodule Voting.Aggregator do
  use GenStage
  import Logger, warn: false
  @moduledoc """
  The GenStage Server module for vote aggregation.
  Collect vote input and aggregate.
  """

  @doc """
  Start the server process.  Args: district name, and type
  """
  def start_link id, children do
    GenStage.start_link __MODULE__, {id, children},
      name: via_tuple(id)
  end

  @doc """
  Initialize the server and persistent state.
  """
  def init {id, nil} do
    {:producer_consumer, %{id: id, votes: %{}}}
  end
  def init {id, children} do
    pids = Enum.map children, & __MODULE__.via_tuple(&1)
    {:producer_consumer, %{id: id, votes: %{}},
      subscribe_to: pids}
  end

  @doc """
  Generate the process registry tuple for a process given the
  district name.  This uses the gproc registry.
  """
  def via_tuple id do
    {:via, :gproc, {:n, :l, {:voting, :aggregator, id}}}
  end

  @doc """
  Submit a single vote to an aggregator
  """
  def submit_vote id, candidate do
    pid = __MODULE__.via_tuple(id)
    :ok = GenStage.call pid, {:submit_vote, candidate}
  end

  @doc """
  Respond to requests
  """
  def handle_call {:submit_vote, candidate}, _from, state do
    n = state.votes[candidate] || 0
    state = %{state | votes: Map.put(state.votes, candidate, n+1)}
    {:reply, :ok, [%{state.id => state.votes}], state}
  end

  @doc """
  Handle events from subordinate aggregators
  """
  def handle_events events, _from, state do
    votes = Enum.reduce events, state.votes, fn e, votes ->
      Enum.reduce e, votes, fn {k,v}, votes ->
        Map.put(votes, k, v) # replace any entries for subordinates
      end
    end
    # Any jurisdiction specific policy would go here

    # sum the votes by candidate for the published event
    merged = Enum.reduce votes, %{}, fn {j, jv}, votes ->
      # Each jourisdiction is summed for each candidate
      Enum.reduce jv, votes, fn {candidate, tot}, votes ->
        Logger.debug "@@@@ Votes in #{inspect j} for #{inspect candidate}: #{inspect tot}"
        n = votes[candidate] || 0
        Map.put(votes, candidate, n + tot)
      end
    end
    # return the published event and the state which retains
    # votes by jourisdiction
    {:noreply, [%{state.id => merged}], %{state | votes: votes}}
  end
end
