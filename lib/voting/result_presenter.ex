defmodule Voting.ResultPresenter do
  use GenStage
  import Logger, warn: false
  @moduledoc """
  This module is a GenStage consumer collecting
  vote results from an aggregator
  """

  @doc """
  Start the server process.
  """
  def start_link id, aggregator_id do
    GenStage.start_link __MODULE__, {id, aggregator_id},
      name: via_tuple(id)
  end

  @doc """
  Initialize the server and persistent state.
  """
  def init {id, aggregator_id} do
    agg_pid = Voting.Aggregator.via_tuple(aggregator_id)
    {:consumer, %{id: id, votes: %{}},
      subscribe_to: [agg_pid]}
  end

  @doc """
  Generate the process registry tuple for a process given the
  id.  This uses the gproc registry.
  """
  def via_tuple id do
    {:via, :gproc, {:n, :l, {:voting, :presenter, id}}}
  end

  @doc """
  Handle requests for results
  """
  def handle_call :get_votes, _from, state do
    {:reply, {:ok, state.votes}, [], state}
  end

  @doc """
  Obtain the results from this presenter
  """
  def get_votes id do
    pid = Voting.ResultPresenter.via_tuple(id)
    {:ok, votes} = GenStage.call pid, :get_votes
    votes
  end

  @doc """
  Receive votes from aggregator
  """
  def handle_events events, _from, state do
    Logger.debug "@@@@ Presenter received: #{inspect events}"
    votes = Enum.reduce events, state.votes, fn v, votes ->
      Enum.reduce v, votes, fn {k,v}, votes ->
        Map.put(votes, k, v)
      end
    end
    {:noreply, [], %{state | votes: votes}}
  end
end
