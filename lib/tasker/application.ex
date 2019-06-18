defmodule Tasker.Application do
  use Application

  def start(_type, _args) do
    Tasker.Supervisor.start_link(:ok)
  end
end
