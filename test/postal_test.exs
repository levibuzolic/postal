defmodule PostalTest do
  use ExUnit.Case

  describe "setup/0" do
    test "initializes libpostal and returns :ok" do
      assert :ok = Postal.setup()
    end

    test "is idempotent" do
      assert :ok = Postal.setup()
      assert :ok = Postal.setup()
    end
  end

  describe "parse_address/1" do
    test "parses a US address into components" do
      assert {:ok, result} = Postal.parse_address("123 Main St, New York, NY 10001")
      assert is_map(result)
      assert result[:house_number] == "123"
      assert result[:road] == "main st"
    end

    test "returns atom-keyed map" do
      {:ok, result} = Postal.parse_address("123 Main St, New York")

      Enum.each(result, fn {key, value} ->
        assert is_atom(key)
        assert is_binary(value)
      end)
    end

    test "handles international addresses" do
      assert {:ok, result} = Postal.parse_address("1 Rue de Rivoli, Paris, France")
      assert is_map(result)
      assert map_size(result) > 0
    end
  end

  describe "parse_address!/1" do
    test "returns the map directly" do
      result = Postal.parse_address!("123 Main St, New York, NY 10001")
      assert is_map(result)
      assert result[:house_number] == "123"
    end
  end

  describe "expand_address/2" do
    test "expands abbreviations" do
      assert {:ok, expansions} = Postal.expand_address("123 Main St")
      assert is_list(expansions)
      assert expansions != []
      assert Enum.any?(expansions, &String.contains?(&1, "main street"))
    end

    test "accepts languages option" do
      assert {:ok, expansions} = Postal.expand_address("Av. Paulista", languages: ["pt"])
      assert is_list(expansions)
      assert expansions != []
    end

    test "works without options" do
      assert {:ok, expansions} = Postal.expand_address("123 Main St")
      assert is_list(expansions)
    end
  end

  describe "expand_address!/2" do
    test "returns the list directly" do
      result = Postal.expand_address!("123 Main St")
      assert is_list(result)
      assert Enum.any?(result, &String.contains?(&1, "main street"))
    end
  end
end
