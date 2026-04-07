# Build an Elixir libpostal NIF package using Rustler

## Goal

Create a new hex-publishable Elixir package that wraps [libpostal](https://github.com/openvenues/libpostal) via a Rust NIF using [Rustler](https://github.com/rusterlium/rustler) and the [postal](https://github.com/pnordahl/rust-postal) Rust crate.

## Why

The only existing Elixir wrapper ([expostal](https://github.com/SweetIQ/expostal)) is unmaintained (last release 2017) and uses raw C NIFs. A Rustler-based package gets memory safety and modern tooling.

## API surface

libpostal has two functions. The package should expose both, plus a setup function:

### `Postal.setup/0`

Pre-initializes libpostal (loads ~2GB data files from disk). Optional — if not called, initialization happens lazily on first `parse_address` or `expand_address` call. Idempotent (safe to call multiple times).

Returns `:ok` or `{:error, reason}`.

Typical usage in `Application.start/2`:

```elixir
def start(_type, _args) do
  :ok = Postal.setup()
  # ...
end
```

### `Postal.parse_address/1` and `Postal.parse_address!/1`

Parses a free-text address into labeled components. Returns an atom-keyed map.

Note: libpostal's parser does not accept language/country options (it ignores them internally),
so `parse_address` takes only the address string.

```elixir
{:ok, %{house_number: "123", road: "main st", city: "new york"}} =
  Postal.parse_address("123 Main St, New York")

# Bang variant raises on error
%{house_number: "123"} = Postal.parse_address!("123 Main St")
```

### `Postal.expand_address/2` and `Postal.expand_address!/2`

Expands/normalizes an address string (e.g. abbreviations). Returns a list of canonical form strings.

```elixir
{:ok, expansions} = Postal.expand_address("123 Main St")

# With language hints
{:ok, expansions} = Postal.expand_address("Av. Paulista, 1578", languages: ["pt"])

# Bang variant raises on error
expansions = Postal.expand_address!("123 Main St")
```

### Options

`expand_address` accepts:
- `languages` (list of strings) — ISO 639-1 language codes to hint the language(s) of the address

Note: libpostal's underlying C API does not support `country` or `language` options for parsing
(they are ignored). The `expand_address` normalizer supports language hints via `set_languages`.

### Return types

- `parse_address` → `{:ok, map()}` with atom keys (e.g. `:house_number`, `:road`, `:city`, `:state`, `:postcode`, `:country`) or `{:error, reason}`
- `expand_address` → `{:ok, [String.t()]}` or `{:error, reason}`
- Bang variants return the unwrapped value or raise `Postal.Error`

### Error handling

- `{:ok, result}` / `{:error, reason}` for standard variants
- Bang variants (`!`) raise `Postal.Error` on failure
- Errors are primarily: libpostal initialization failure, invalid arguments

## Technical approach

- Use Rustler to define NIF functions in Rust
- Depend on the `postal` Rust crate (v0.2.x, https://crates.io/crates/postal) which provides safe Rust bindings over libpostal's C FFI
- Initialization is lazy by default: the NIF ensures `libpostal_setup()` has been called before every operation. The Rust `postal` crate handles thread-safe one-time init.
- `Postal.setup/0` allows eager pre-initialization at app boot (idempotent, same underlying mechanism)
- The package assumes libpostal's C library and data files are already installed on the system

## Package structure

```
lib/
  postal.ex             # Public API module (setup, parse_address, expand_address + bang variants)
  postal/
    native.ex           # Rustler NIF module (internal, not public API)
    error.ex            # Postal.Error exception
native/
  postal_nif/
    src/lib.rs          # Rustler NIF implementation
    Cargo.toml          # Depends on postal crate
mix.exs                 # Depends on rustler
test/
  postal_test.exs
```

## Prerequisites for users

- Rust toolchain (rustup)
- libpostal C library compiled and installed (`libpostal_setup` data files downloaded)
- Document installation steps for macOS and Linux

## Reference

- Existing (unmaintained) package: https://github.com/SweetIQ/expostal
- Rust crate: https://github.com/pnordahl/rust-postal
- libpostal: https://github.com/openvenues/libpostal
- Rustler: https://github.com/rusterlium/rustler
