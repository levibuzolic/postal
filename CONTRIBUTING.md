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
   mix compile
   ```

3. Run the checks:
   ```sh
   mix test
   mix format --check-formatted
   mix credo --strict
   mix dialyzer
   ```

## Code quality

All code must pass before merging:

- `mix format --check-formatted`
- `mix credo --strict`
- `mix dialyzer`
- `mix test`

CI runs all of these on every push and PR.

## Releasing

Releases are driven through the GitHub UI. Publishing to Hex is fully automated.

### One-time setup

Add a `HEX_API_KEY` secret to the repo:

1. Generate a key: `mix hex.user key generate`
2. Go to **Settings > Secrets and variables > Actions**
3. Add a secret named `HEX_API_KEY` with the generated key

### Release process

1. **Bump the version** in `mix.exs` (`@version "x.y.z"`)
2. **Commit and push** to `main`
3. **Create a release** in the GitHub UI:
   - Go to [Releases > Draft a new release](https://github.com/levibuzolic/postal/releases/new)
   - Click **Choose a tag**, type `vX.Y.Z` (matching the version in mix.exs), and select **Create new tag**
   - Click **Generate release notes** to auto-populate from merged PRs
   - Click **Publish release**
4. The release workflow will automatically:
   - Verify the tag matches the version in `mix.exs`
   - Build the package
   - Publish to [Hex](https://hex.pm/packages/postal)

If the tag doesn't match the version in `mix.exs`, the workflow will fail with an error — fix the version and create a new release.

### CLI alternative

If you prefer the command line:

```sh
# After bumping @version in mix.exs and committing:
git tag v0.2.0
git push origin v0.2.0
# Then create the release in the GitHub UI from the existing tag,
# or use the gh CLI:
gh release create v0.2.0 --generate-notes
```
