defmodule Postal do
  @moduledoc """
  Elixir bindings for [libpostal](https://github.com/openvenues/libpostal), a fast
  statistical parser/normalizer for street addresses around the world.

  Postal wraps libpostal via a Rust NIF using [Rustler](https://github.com/rusterlium/rustler),
  providing memory-safe, high-performance address parsing and normalization.

  ## Features

  - **Address parsing** — decompose free-text addresses into structured components
    (house number, road, city, state, postcode, country, etc.)
  - **Address expansion** — normalize addresses by expanding abbreviations, converting
    to canonical forms, and handling international formats

  ## Setup

  libpostal requires a one-time initialization that loads its data files (~2GB) into memory.
  This happens automatically on the first call to `parse_address/1` or `expand_address/2`,
  but you can pre-initialize at application boot to avoid the first-call latency:

      # In your Application.start/2
      def start(_type, _args) do
        :ok = Postal.setup()

        children = [
          # ...
        ]

        Supervisor.start_link(children, strategy: :one_for_one)
      end

  ## Prerequisites

  - **Rust toolchain** — install via [rustup](https://rustup.rs/)
  - **libpostal C library** — must be compiled and installed on your system with data files
    downloaded. See the [libpostal README](https://github.com/openvenues/libpostal#installation)
    for instructions.

  ## Examples

      # Parse a free-text address into components
      {:ok, result} = Postal.parse_address("123 Main St, New York, NY 10001")
      # => {:ok, %{house_number: "123", road: "main st", city: "new york", state: "ny", postcode: "10001"}}

      # Expand/normalize an address
      {:ok, expansions} = Postal.expand_address("123 Main St NYC")
      # => {:ok, ["123 main street new york city", ...]}

      # Use language hints for better expansion accuracy
      {:ok, expansions} = Postal.expand_address("Av. Paulista, 1578", languages: ["pt"])
  """

  @typedoc """
  Options accepted by `expand_address/2`.

  - `:languages` — a list of ISO 639-1 language codes (e.g. `["en"]`, `["fr", "de"]`) to hint
    the language(s) of the address. Improves normalization accuracy for multilingual regions.
  """
  @type expand_option :: {:languages, [String.t()]}

  @typedoc """
  A parsed address represented as an atom-keyed map.

  Common keys returned by libpostal include:

  - `:house_number` — street number (e.g. `"123"`)
  - `:road` — street name (e.g. `"main street"`)
  - `:suburb` — neighbourhood or suburb
  - `:city` — city or town name
  - `:city_district` — borough or district within a city
  - `:state` — state or province
  - `:state_district` — sub-state administrative region
  - `:postcode` — postal/zip code
  - `:country` — country name
  - `:unit` — apartment or unit number
  - `:level` — floor or level
  - `:staircase` — staircase identifier
  - `:entrance` — entrance identifier
  - `:po_box` — PO box number
  - `:house` — named building or house
  - `:category` — place category (e.g. `"restaurant"`)
  - `:near` — nearby landmark or reference
  - `:world_region` — continent or world region
  - `:island` — island name

  Not all keys will be present — only components identified in the input address are returned.
  """
  @type parsed_address :: %{optional(atom()) => String.t()}

  # libpostal's fixed set of address component labels.
  # Referencing them here ensures the atoms exist for String.to_existing_atom/1.
  @known_labels ~w(
    house_number road suburb city city_district state state_district
    postcode country unit level staircase entrance po_box house
    category near world_region island
  )a
  _ = @known_labels

  @doc """
  Pre-initializes libpostal by loading its data files into memory.

  This is **optional** — if not called, initialization happens lazily on the first call to
  `parse_address/1` or `expand_address/2`. However, initialization loads ~2GB of data files
  and can take 1-2 seconds, so calling `setup/0` at application boot avoids unexpected
  latency on the first request.

  Idempotent — safe to call multiple times. Subsequent calls are no-ops.

  ## Examples

      Postal.setup()
      #=> :ok

  ## Typical usage

      # In your Application module
      def start(_type, _args) do
        :ok = Postal.setup()
        Supervisor.start_link(children, strategy: :one_for_one)
      end
  """
  @spec setup() :: :ok | {:error, String.t()}
  def setup do
    Postal.Native.setup()
  end

  @doc """
  Parses a free-text address string into labeled components.

  Uses libpostal's statistical address parser to decompose an address into structured
  fields like house number, road, city, state, postcode, and country. The parser supports
  addresses from around the world in many languages and formats.

  Returns `{:ok, map}` where the map has atom keys for each identified component,
  or `{:error, reason}` if parsing fails.

  ## Examples

      Postal.parse_address("123 Main St, New York, NY 10001")
      #=> {:ok, %{house_number: "123", road: "main st", city: "new york", state: "ny", postcode: "10001"}}

      Postal.parse_address("1 Rue de Rivoli, Paris")
      #=> {:ok, %{house_number: "1", road: "rue de rivoli", city: "paris"}}

  ## Notes

  - libpostal normalizes text to lowercase in its output
  - The set of keys in the result depends on the input — only identified components are included
  - Results are statistical best-guesses, not deterministic parses
  """
  @spec parse_address(String.t()) :: {:ok, parsed_address()} | {:error, String.t()}
  def parse_address(address) when is_binary(address) do
    case Postal.Native.parse_address(address) do
      {:ok, components} ->
        map =
          Map.new(components, fn {label, value} ->
            {String.to_existing_atom(label), value}
          end)

        {:ok, map}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `parse_address/1` but raises `Postal.Error` on failure.

  ## Examples

      Postal.parse_address!("123 Main St, New York, NY 10001")
      #=> %{house_number: "123", road: "main st", city: "new york", state: "ny", postcode: "10001"}
  """
  @spec parse_address!(String.t()) :: parsed_address()
  def parse_address!(address) do
    case parse_address(address) do
      {:ok, result} -> result
      {:error, reason} -> raise Postal.Error, message: reason
    end
  end

  @doc """
  Expands and normalizes an address string into canonical forms.

  Uses libpostal's address normalizer to expand abbreviations (e.g. "St" to "street",
  "NYC" to "new york city") and produce one or more canonical representations of the
  input address. This is useful for deduplication and matching.

  Returns `{:ok, expansions}` where `expansions` is a list of normalized address strings,
  or `{:error, reason}` if expansion fails.

  ## Options

  - `:languages` — a list of ISO 639-1 language codes (e.g. `["en"]`, `["fr", "de"]`).
    Hints the language(s) of the address to improve normalization accuracy.

  ## Examples

      Postal.expand_address("123 Main St NYC")
      #=> {:ok, ["123 main street new york city", ...]}

      Postal.expand_address("Av. Paulista, 1578", languages: ["pt"])
      #=> {:ok, ["avenida paulista 1578", ...]}

  ## Notes

  - Multiple expansions may be returned when there are ambiguous abbreviations
  - Output is normalized to lowercase
  - Useful for address deduplication — expand both addresses and compare the results
  """
  @spec expand_address(String.t(), [expand_option()]) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def expand_address(address, opts \\ []) when is_binary(address) do
    languages = Keyword.get(opts, :languages, [])
    Postal.Native.expand_address(address, languages)
  end

  @doc """
  Same as `expand_address/2` but raises `Postal.Error` on failure.

  ## Examples

      Postal.expand_address!("123 Main St NYC")
      #=> ["123 main street new york city", ...]
  """
  @spec expand_address!(String.t(), [expand_option()]) :: [String.t()]
  def expand_address!(address, opts \\ []) do
    case expand_address(address, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Postal.Error, message: reason
    end
  end
end
