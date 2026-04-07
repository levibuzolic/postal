# Postal

[![CI](https://github.com/levibuzolic/postal/actions/workflows/ci.yml/badge.svg)](https://github.com/levibuzolic/postal/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/postal.svg)](https://hex.pm/packages/postal)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/postal)
[![License](https://img.shields.io/hexpm/l/postal.svg)](https://github.com/levibuzolic/postal/blob/main/LICENSE)

Elixir bindings for [libpostal](https://github.com/openvenues/libpostal), powered by a Rust NIF via [Rustler](https://github.com/rusterlium/rustler).

## What is libpostal?

[libpostal](https://github.com/openvenues/libpostal) is a C library for parsing and normalizing street addresses around the world. It uses statistical NLP models trained on OpenStreetMap data covering addresses in over 200 countries and territories. Unlike regex-based parsers, libpostal handles the enormous variety of global address formats -- from "123 Main St" to "1-2-3 Shibuya, Tokyo" to "Flat 4, 22 Acacia Avenue, London."

libpostal provides two core operations:

- **Address parsing** -- decompose a free-text address string into labeled components (house number, street, city, state, postcode, country, etc.)
- **Address expansion** -- normalize an address by expanding abbreviations ("St" to "Street", "NYC" to "New York City") and producing canonical forms, useful for deduplication and matching

Postal brings these capabilities to Elixir.

## Why Postal?

An Elixir libpostal binding already exists in [expostal](https://github.com/SweetIQ/expostal), but it has been unmaintained since 2017. Postal is a modern replacement with several advantages:

- **Memory safety** -- uses Rust NIFs via Rustler instead of raw C NIFs, eliminating an entire class of memory bugs that can crash the BEAM
- **Precompiled binaries** -- ships precompiled NIF binaries for common platforms (macOS, Linux), so most users don't need a Rust toolchain installed
- **Maintained** -- actively developed and compatible with current Elixir/OTP versions
- **Better API** -- `{:ok, result}` / `{:error, reason}` tuples with bang variants, atom-keyed maps, and language hints for address expansion

## Prerequisites

- **Elixir** ~> 1.19
- **libpostal C library** -- must be installed with data files (required at runtime)
- **Rust toolchain** -- only needed if building the NIF from source (see [Building from source](#building-from-source))

### Installing libpostal

**macOS (Homebrew):**

```sh
brew install libpostal
```

**Ubuntu/Debian (build from source):**

```sh
git clone https://github.com/openvenues/libpostal
cd libpostal
./bootstrap.sh
./configure
make
sudo make install
sudo ldconfig
```

See the [libpostal README](https://github.com/openvenues/libpostal#installation) for full instructions.

## Installation

Add `postal` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postal, "~> 0.1.0"}
  ]
end
```

Then run `mix deps.get`.

## Usage

### Parsing addresses

Break a free-text address into structured components:

```elixir
{:ok, result} = Postal.parse_address("123 Main St, New York, NY 10001")
# => {:ok, %{house_number: "123", road: "main st", city: "new york", state: "ny", postcode: "10001"}}

# Bang variant raises on failure
result = Postal.parse_address!("1 Rue de Rivoli, Paris")
# => %{house_number: "1", road: "rue de rivoli", city: "paris"}
```

### Expanding/normalizing addresses

Expand abbreviations and produce canonical forms (useful for deduplication and matching):

```elixir
{:ok, expansions} = Postal.expand_address("123 Main St NYC")
# => {:ok, ["123 main street new york city", ...]}

# Pass language hints for better accuracy
{:ok, expansions} = Postal.expand_address("Av. Paulista, 1578", languages: ["pt"])
# => {:ok, ["avenida paulista 1578", ...]}
```

## Configuration

libpostal loads ~2GB of data files into memory on first use. By default this happens lazily on the first call to `parse_address/1` or `expand_address/2`.

To avoid first-call latency, you can initialize eagerly at application boot:

```elixir
# In your Application module
def start(_type, _args) do
  :ok = Postal.setup()

  children = [
    # ...
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
end
```

`setup/0` is idempotent -- subsequent calls are no-ops.

## Building from source

By default, Postal uses precompiled NIF binaries. To compile the Rust NIF from source (e.g. for development or unsupported platforms), you need the Rust toolchain installed and can set:

```sh
POSTAL_BUILD=1 mix deps.compile postal
```

## Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/postal).

## License

MIT -- see [LICENSE](LICENSE) for details.
