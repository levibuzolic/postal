# Postal

Elixir bindings for [libpostal](https://github.com/openvenues/libpostal) -- a fast statistical parser/normalizer for street addresses around the world, powered by a Rust NIF via [Rustler](https://github.com/rusterlium/rustler).

## Prerequisites

- **Elixir** ~> 1.19
- **Rust toolchain** -- install via [rustup](https://rustup.rs/)
- **libpostal C library** -- must be installed with data files

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

## Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/postal).

## License

MIT -- see [LICENSE](LICENSE) for details.
