defmodule VotingTest do
  use ExUnit.Case

  # setup _context do
  #   Voting.AggregatorSupervisor.stop_all_aggregators
  #   Voting.ResultPresenterSupervisor.stop_all_presenters
  #   :ok
  # end

  test "Basic vote collection" do
    # Create 1 aggregator for state of CA
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "CA", nil
    # Create a presenter to receive the results
    {:ok, _} = Voting.ResultPresenterSupervisor.start_presenter "CA", "CA"
    try do
      # cast a vote for candidate Tom
      Voting.VoteRecorder.cast_vote "CA", "Tom"
      # Verify total in presenter
      Process.sleep(1000)
      votes = Voting.ResultPresenter.get_votes "CA"
      assert votes == %{"CA" => %{"Tom" => 1}}
    after
      Voting.AggregatorSupervisor.stop_all_aggregators
      Voting.ResultPresenterSupervisor.stop_all_presenters
    end
  end

  test "Vote Aggregation for one candidate" do
    # Create 1 aggregator for state of CA
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "CA", nil
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "NV", nil
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "US", ["CA", "NV"]
    # Create a presenter to receive the results
    {:ok, _} = Voting.ResultPresenterSupervisor.start_presenter "US", "US"
    try do
      # cast a vote for candidate Tom
      Voting.VoteRecorder.cast_vote "CA", "Tom"
      Voting.VoteRecorder.cast_vote "NV", "Tom"
      # Verify total in presenter
      Process.sleep(1000)
      votes = Voting.ResultPresenter.get_votes "US"
      assert votes == %{"US" => %{"Tom" => 2}}
    after
      Voting.AggregatorSupervisor.stop_all_aggregators
      Voting.ResultPresenterSupervisor.stop_all_presenters
    end
  end

  test "Vote Aggregation for two candidates" do
    # Create 1 aggregator for state of CA
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "CA", nil
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "NV", nil
    {:ok, _} = Voting.AggregatorSupervisor.start_aggregator "US", ["CA", "NV"]
    # Create a presenter to receive the results
    {:ok, _} = Voting.ResultPresenterSupervisor.start_presenter "US", "US"
    try do
      # cast a vote for candidate Tom
      Voting.VoteRecorder.cast_vote "CA", "Tom"
      Voting.VoteRecorder.cast_vote "NV", "Fred"
      # Verify total in presenter
      Process.sleep(1000)
      votes = Voting.ResultPresenter.get_votes "US"
      assert votes == %{"US" => %{"Tom" => 1, "Fred" => 1}}
    after
      Voting.AggregatorSupervisor.stop_all_aggregators
      Voting.ResultPresenterSupervisor.stop_all_presenters
    end
  end
end
