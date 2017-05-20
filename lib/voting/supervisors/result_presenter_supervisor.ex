defmodule Voting.ResultPresenterSupervisor do
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
      worker(Voting.ResultPresenter, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end

  @doc """
  Start a result presenter server
  """
  def start_presenter id, aggregator_id do
    {:ok, pid} = Supervisor.start_child __MODULE__, [id, aggregator_id]
    {:ok, pid}
  end

  @doc """
  Stop a result presenter server
  """
  def stop_presenter id do
    {:via, :gproc, name} = Voting.ResultPresenter.via_tuple(id)
    pid = :gproc.lookup_pid(name)
    Supervisor.terminate_child __MODULE__, pid
  end

  @doc """
  Termnate all aggregator servers
  """
  def stop_all_presenters do
    # Logger.debug "@@@@ Stopping all aggregators"
    Supervisor.which_children(__MODULE__)
    |> Enum.each(fn child ->
      {_id, pid, _type, _mod} = child
      Supervisor.terminate_child __MODULE__, pid
    end)
  end
end
