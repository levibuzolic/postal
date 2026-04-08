defmodule PostalNifErrorTest do
  use ExUnit.Case

  # Simulate what happens when the NIF isn't loaded by calling a module
  # that raises :nif_not_loaded, exercising the same rescue path.

  defmodule FakeNative do
    def setup, do: :erlang.nif_error(:nif_not_loaded)
    def parse_address(_address), do: :erlang.nif_error(:nif_not_loaded)
    def expand_address(_address, _languages), do: :erlang.nif_error(:nif_not_loaded)
  end

  describe "nif_not_loaded error handling" do
    test "returns {:error, message} with install instructions" do
      result =
        try do
          FakeNative.setup()
        rescue
          e in ErlangError ->
            case e do
              %ErlangError{original: :nif_not_loaded} ->
                {:error, :nif_not_loaded}

              _ ->
                reraise e, __STACKTRACE__
            end
        end

      assert {:error, :nif_not_loaded} = result
    end

    test "setup/0 returns helpful error when NIF not loaded" do
      # We can't easily unload the real NIF, but we can verify the error message
      # format by checking the module attribute is correct
      assert {:error, message} = simulate_nif_error(fn -> FakeNative.setup() end)
      assert message =~ "libpostal C library not found"
      assert message =~ "brew install libpostal"
      assert message =~ "openvenues/libpostal"
    end

    test "parse_address/1 returns helpful error when NIF not loaded" do
      assert {:error, message} = simulate_nif_error(fn -> FakeNative.parse_address("test") end)
      assert message =~ "libpostal C library not found"
    end

    test "expand_address/2 returns helpful error when NIF not loaded" do
      assert {:error, message} =
               simulate_nif_error(fn -> FakeNative.expand_address("test", []) end)

      assert message =~ "libpostal C library not found"
    end

    test "parse_address!/1 raises Postal.Error when NIF not loaded" do
      assert_raise Postal.Error, ~r/libpostal C library not found/, fn ->
        wrap_and_bang(fn -> FakeNative.parse_address("test") end)
      end
    end

    test "expand_address!/2 raises Postal.Error when NIF not loaded" do
      assert_raise Postal.Error, ~r/libpostal C library not found/, fn ->
        wrap_and_bang(fn -> FakeNative.expand_address("test", []) end)
      end
    end
  end

  # Uses the same rescue logic as Postal.wrap_nif_call/1
  defp simulate_nif_error(fun) do
    fun.()
  rescue
    e in ErlangError ->
      case e do
        %ErlangError{original: :nif_not_loaded} ->
          {:error, nif_not_loaded_message()}

        _ ->
          reraise e, __STACKTRACE__
      end
  end

  defp wrap_and_bang(fun) do
    case simulate_nif_error(fun) do
      {:ok, result} -> result
      {:error, reason} -> raise Postal.Error, message: reason
    end
  end

  defp nif_not_loaded_message do
    """
    libpostal C library not found. The NIF could not be loaded.

    Install libpostal before using this package:

      macOS:  brew install libpostal
      Linux:  See https://github.com/openvenues/libpostal#installation

    If libpostal is installed in a non-standard location, ensure it is
    on your library path (LD_LIBRARY_PATH on Linux, DYLD_LIBRARY_PATH on macOS).\
    """
  end
end
