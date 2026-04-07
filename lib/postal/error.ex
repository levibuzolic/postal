defmodule Postal.Error do
  @moduledoc """
  Exception raised by bang variants of `Postal` functions.
  """

  defexception [:message]
end
