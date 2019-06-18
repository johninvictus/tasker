defmodule Tasker.Coordinator do
  require Logger

  @moduledoc """
  This module is used to intercept the results of worker processes
  """

  def loop(state \\ [], city_count, owner) do
    receive do
      {:ok, response} ->
        new_state = [response | state]

        if(city_count == Enum.count(new_state)) do
          send(self(), :exit)
        end

        loop(new_state, city_count, owner)

      :exit ->
        result =
          state
          |> Enum.sort()
          |> Enum.join(", ")

        send(owner, {:ok, result})

      _ ->
        loop(state, city_count, owner)
    end
  end
end
