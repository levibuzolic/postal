# Postal - Elixir libpostal NIF Package

## Overview

Elixir package wrapping [libpostal](https://github.com/openvenues/libpostal) via Rust NIF using [Rustler](https://github.com/rusterlium/rustler) and the [postal](https://github.com/pnordahl/rust-postal) Rust crate. Intended for publishing on Hex.

See [PLAN.md](PLAN.md) for the full implementation plan.

## Repository

- **GitHub:** https://github.com/levibuzolic/postal
- **Language:** Elixir + Rust (NIF via Rustler)
- **Min Elixir:** ~> 1.19

## API Surface

Three public functions in `Postal` (plus bang variants):

- `setup/0` — pre-initialize libpostal (optional, lazy init by default)
- `parse_address/1` / `parse_address!/1` — parse free-text address into atom-keyed map
- `expand_address/2` / `expand_address!/2` — expand/normalize address into canonical forms

`expand_address` accepts a `languages` option (list of ISO 639-1 codes).

## Project Structure

```
lib/
  postal.ex                    # Public API module (setup, parse_address, expand_address + bang variants)
  postal/
    native.ex                  # Rustler NIF module (internal)
    error.ex                   # Postal.Error exception
native/
  postal_nif/
    src/lib.rs                 # Rustler NIF implementation
    Cargo.toml                 # Depends on postal + rustler crates
mix.exs                        # Depends on rustler, credo, dialyxir, ex_doc
test/postal_test.exs           # Tests
```

## Development

### Prerequisites

- [mise](https://mise.jdx.dev/) for version management (see `mise.toml`)
- Rust toolchain (rustup)
- libpostal C library installed with data files

### Commands

```sh
mix deps.get          # Fetch dependencies
mix compile           # Compile (includes Rust NIF build)
mix test              # Run tests
mix format            # Format code
mix format --check-formatted  # Check formatting (CI)
mix credo --strict    # Lint
mix dialyzer          # Static type analysis
```

### CI

GitHub Actions runs on every push/PR:
- `mix format --check-formatted`
- `mix credo --strict`
- `mix dialyzer`
- `mix test`

See `.github/workflows/ci.yml`.

### Code Quality Standards

- All code must pass `mix format --check-formatted`
- All code must pass `mix credo --strict`
- All code must pass `mix dialyzer` (keep PLT cache in CI)
- All tests must pass
- Write typespecs for all public functions
