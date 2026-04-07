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

Releases are a two-step process: build precompiled NIFs, then publish to Hex.

### One-time setup

Add a `HEX_API_KEY` secret to the `hex-publish` environment:

1. Generate a key: `mix hex.user key generate`
2. Go to **Settings > Environments > hex-publish > Environment secrets**
3. Add a secret named `HEX_API_KEY` with the generated key

### Release process

1. **Bump the version** in `mix.exs` (`@version "x.y.z"`)
2. **Commit and push** to `main`
3. **Push a tag:**
   ```sh
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
4. **Wait for NIF builds** -- the `Build precompiled NIFs` workflow builds binaries for all targets and attaches them to a draft GitHub release. Check the [Actions tab](https://github.com/levibuzolic/postal/actions) to monitor progress.
5. **Publish the release** in the GitHub UI:
   - Go to [Releases](https://github.com/levibuzolic/postal/releases), find the draft release
   - Click **Generate release notes**, review, and click **Publish release**
6. The `Release` workflow triggers automatically:
   - Verifies the tag matches the version in `mix.exs`
   - Downloads all precompiled binaries and generates checksums
   - Publishes to [Hex](https://hex.pm/packages/postal)

### CLI alternative

```sh
# After bumping @version in mix.exs and committing:
git tag v0.2.0
git push origin v0.2.0
# Wait for NIF builds to complete, then:
gh release edit v0.2.0 --draft=false
# Or create from scratch:
gh release create v0.2.0 --generate-notes
```

### Precompiled NIF targets

Binaries are built for these platforms:

| Target | Description |
|--------|-------------|
| `aarch64-apple-darwin` | macOS Apple Silicon |
| `x86_64-apple-darwin` | macOS Intel |
| `x86_64-unknown-linux-gnu` | Linux x86_64 |
| `aarch64-unknown-linux-gnu` | Linux ARM64 |
