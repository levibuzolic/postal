# Contributing

## Development setup

1. Install prerequisites:
   - [mise](https://mise.jdx.dev/) for version management
   - [Rust toolchain](https://rustup.rs/)
   - libpostal C library (macOS: `brew install libpostal`)

2. Clone and set up:
   ```sh
   git clone https://github.com/levibuzolic/postal
   cd postal
   mise install
   mix deps.get
   POSTAL_BUILD=1 mix compile
   ```

3. Run the checks:
   ```sh
   mix test
   mix format --check-formatted
   mix credo --strict
   mix dialyzer
   ```

Note: `POSTAL_BUILD=1` is required during development to compile the Rust NIF from source instead of downloading a precompiled binary.

## Code quality

All code must pass before merging:

- `mix format --check-formatted`
- `mix credo --strict`
- `mix dialyzer`
- `mix test`

CI runs all of these on every push and PR.

## Releasing

Pushing a version tag triggers the full release pipeline automatically: build precompiled NIFs, generate checksums, create a GitHub release, and publish to Hex.

### One-time setup

Add a `HEX_API_KEY` secret to the `hex-publish` environment:

1. Generate a key: `mix hex.user key generate`
2. Go to **Settings > Environments > hex-publish > Environment secrets**
3. Add a secret named `HEX_API_KEY` with the generated key

### Release process

1. **Bump the version** in `mix.exs` (`@version "x.y.z"`)
2. **Commit and push** to `main`
3. **Tag and push:**
   ```sh
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
4. The release workflow runs automatically:
   - Builds precompiled NIF binaries for all targets (in parallel)
   - Verifies the tag matches the version in `mix.exs`
   - Generates checksums for all precompiled binaries
   - Publishes to [Hex](https://hex.pm/packages/postal)
   - Creates a GitHub release with auto-generated notes

Monitor progress in the [Actions tab](https://github.com/levibuzolic/postal/actions).

### Precompiled NIF targets

Binaries are built for these platforms:

| Target | Description |
|--------|-------------|
| `aarch64-apple-darwin` | macOS Apple Silicon |
| `x86_64-apple-darwin` | macOS Intel |
| `x86_64-unknown-linux-gnu` | Linux x86_64 |
| `aarch64-unknown-linux-gnu` | Linux ARM64 |
