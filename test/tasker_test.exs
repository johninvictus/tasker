defmodule TaskerTest do
  use ExUnit.Case
  doctest Tasker

  test "greets the world" do
    assert Tasker.hello() == :world
  end
end
