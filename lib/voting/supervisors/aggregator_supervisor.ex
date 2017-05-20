defmodule Voting.AggregatorSupervisor do
  use Supervisor
  import Logger, warn: false

  @moduledoc """
  This supervisor is the root of the dynamic TemplateType supervisison
  tree.  It has one child for each template type defined.
  """

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init [] do
    children = [
      worker(Voting.Aggregator, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end

  @doc """
  Start an aggregator server
  """
  def start_aggregator id, children do
    {:ok, pid} = Supervisor.start_child __MODULE__, [id, children]
    {:ok, pid}
  end

  @doc """
  Stop an aggregator server
  """
  def stop_aggregator id do
    {:via, :gproc, name} = Voting.Aggregator.via_tuple(id)
    pid = :gproc.lookup_pid(name)
    Supervisor.terminate_child __MODULE__, pid
  end

  @doc """
  Termnate all aggregator servers
  """
  def stop_all_aggregators do
    # Logger.debug "@@@@ Stopping all aggregators"
    Supervisor.which_children(__MODULE__)
    |> Enum.each(fn child ->
      {_id, pid, _type, _mod} = child
      Supervisor.terminate_child __MODULE__, pid
    end)
  end
end
