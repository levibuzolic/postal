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

    test "handles empty string" do
      assert {:ok, result} = Postal.parse_address("")
      assert is_map(result)
    end

    test "handles unicode addresses" do
      assert {:ok, result} = Postal.parse_address("東京都渋谷区")
      assert is_map(result)
      assert map_size(result) > 0
    end

    test "handles German unicode addresses" do
      assert {:ok, result} = Postal.parse_address("Königstraße 1, München")
      assert is_map(result)
      assert map_size(result) > 0
    end

    test "handles address with only a country" do
      assert {:ok, result} = Postal.parse_address("France")
      assert is_map(result)
      assert map_size(result) > 0
    end

    test "handles address with only a postcode" do
      assert {:ok, result} = Postal.parse_address("10001")
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

    test "works with unicode address" do
      result = Postal.parse_address!("東京都渋谷区")
      assert is_map(result)
      assert map_size(result) > 0
    end

    test "works with empty string" do
      result = Postal.parse_address!("")
      assert is_map(result)
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

    test "handles empty string" do
      assert {:ok, expansions} = Postal.expand_address("")
      assert is_list(expansions)
    end

    test "handles unicode addresses" do
      assert {:ok, expansions} = Postal.expand_address("Königstraße 1, München")
      assert is_list(expansions)
      assert expansions != []
    end

    test "handles single component address" do
      assert {:ok, expansions} = Postal.expand_address("France")
      assert is_list(expansions)
      assert expansions != []
    end

    test "accepts multiple languages option" do
      assert {:ok, expansions} = Postal.expand_address("Av. Paulista", languages: ["en", "fr"])
      assert is_list(expansions)
      assert expansions != []
    end
  end

  describe "expand_address!/2" do
    test "returns the list directly" do
      result = Postal.expand_address!("123 Main St")
      assert is_list(result)
      assert Enum.any?(result, &String.contains?(&1, "main street"))
    end

    test "works with unicode address" do
      result = Postal.expand_address!("Königstraße 1, München")
      assert is_list(result)
      assert result != []
    end

    test "works with empty string" do
      result = Postal.expand_address!("")
      assert is_list(result)
    end

    test "works with multiple languages" do
      result = Postal.expand_address!("Av. Paulista", languages: ["en", "fr"])
      assert is_list(result)
      assert result != []
    end
  end
end
