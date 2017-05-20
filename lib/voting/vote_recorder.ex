defmodule Voting.VoteRecorder do
  @moduledoc """
  This module receives vots and sends them to the proper
  aggregator.  This module uses supervised tasks to ensure
  that any failure is recovered from and the vote is not
  lost.
  """

  @doc """
  Start a task to track the submittal of a vote to an
  aggregator.  This is a supervised task to ensure
  completion.
  """
  def cast_vote where, who do
    Task.Supervisor.async_nolink(Voting.VoteTaskSupervisor,
      fn ->
        Voting.Aggregator.submit_vote where, who
      end)
    |> Task.await
  end
end
