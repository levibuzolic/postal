defmodule PostalTest do
  use ExUnit.Case
  doctest Postal

  test "greets the world" do
    assert Postal.hello() == :world
  end
end
