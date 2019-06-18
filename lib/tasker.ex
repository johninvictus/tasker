defmodule Tasker do
  @moduledoc """
  Documentation for Tasker.
  """
  alias Tasker.{
    Coordinator,
    Worker
  }

  require Logger

  def master_cordinator(cities) when is_list(cities) do
    cordinator = spawn(Coordinator, :loop, [[], Enum.count(cities), self()])

    cities
    |> Enum.each(fn city ->
      pid = spawn(Worker, :loop, [])
      send(pid, {cordinator, city})
    end)

    # receive final results
    receive do
      {:ok, data} ->
        data
    after
      5000 ->
        IO.puts("time out")
    end
  end

  def master_cordinator(_), do: IO.puts("you should provide a list of cities")

  def manual_method(cities) when is_list(cities) do
    owner = self()

    results =
      cities
      |> Enum.map(fn city ->
        pid = spawn(Worker, :loop, [])
        send(pid, {owner, city})
      end)
      |> Enum.map(fn _pid ->
        receive do
          {:ok, temp} ->
            "#{temp}"

          {:error, result} ->
            "#{result}"
        end
      end)

    results |> present_results()
  end

  def manual_method(_), do: IO.puts("you should provide a list of cities")

  @doc """
  Using Task.async(), provided by elixir
  """
  def async(cities) when is_list(cities) do
    results =
      cities
      |> Enum.map(fn city ->
        Task.async(fn -> Worker.temperature_of(city) end)
      end)
      |> Enum.map(&Task.await(&1, :infinity))

    results
    |> Enum.map(fn value ->
      case value do
        {:ok, city, temp} ->
          "#{city} #{temp}"

        {:error, city, _reason} ->
          "#{city} temp not found"
      end
    end)
    |> present_results()
  end

  @doc """
  dynamic
  Task.Supervisor
  """
  def supervised_task(cities) when is_list(cities) do
    results =
      cities
      |> Enum.map(fn city ->
        Task.Supervisor.async(Tasker.TaskSupervisor, Worker, :temperature_of, [city])
      end)
      |> Enum.map(&Task.await(&1, :infinity))

    results
    |> Enum.map(fn value ->
      case value do
        {:ok, city, temp} ->
          "#{city} #{temp}"

        {:error, city, _reason} ->
          "#{city} temp not found"
      end
    end)
    |> present_results()
  end

  @doc """
  This function will spawn process in multiple nodes in a cluster
  """
  def task_distributed(cities) when is_list(cities) do
    master_node = :"master@127.0.0.1"
    slave_nodes = [:"s1@127.0.0.1", :"s2@127.0.0.1", :"s3@127.0.0.1"]

    # start the master node
    master_node |> Node.start()

    # connect to other nodes, make sure they are up
    # use different terminals
    slave_nodes |> Enum.each(&Node.connect/1)

    # now everything is started let create maths to give jobs
    # just simple maths to give jobs
    nodes = [node() | Node.list()]

    # Now let give each node a task untils all tasks are all given out.
    node_job_dispatcher(nodes, cities, [])
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.map(fn value ->
      case value do
        {:ok, city, temp} ->
          "#{city} #{temp}"

        {:error, city, _reason} ->
          "#{city} temp not found"
      end
    end)
    |> present_results()
  end

  defp node_job_dispatcher(_nodes, [], comm), do: comm

  defp node_job_dispatcher([node_x | n_tail], [city | c_tail], comm) do
    task =
      Task.Supervisor.async(
        {Tasker.TaskSupervisor, node_x},
        Worker,
        :temperature_of,
        [city]
      )

    node_job_dispatcher(n_tail ++ [node_x], c_tail, [task | comm])
  end

  defp present_results(results) do
    results
    |> Enum.sort()
    |> Enum.join(", ")
  end
end
