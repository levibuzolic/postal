# Precompiled NIFs via rustler_precompiled

## Goal

Eliminate the Rust toolchain requirement for end users by shipping precompiled NIF binaries for common targets. Users still need libpostal's C library installed at runtime (the NIF dynamically links to it).

If no precompiled binary matches the user's platform, compilation falls back to building from source via Rustler (same as today).

## Targets

Native runners only — no cross-compilation. Covers the vast majority of Elixir deployments.

| Target | CI Runner | libpostal install |
|--------|-----------|-------------------|
| `aarch64-apple-darwin` | `macos-15` | `brew install libpostal` |
| `x86_64-apple-darwin` | `macos-13` | `brew install libpostal` |
| `x86_64-unknown-linux-gnu` | `ubuntu-latest` | build from source |
| `aarch64-unknown-linux-gnu` | `ubuntu-24.04-arm` | build from source |

NIF version: **2.17** (OTP 27+, matching Elixir ~> 1.19 and 1.20 compatibility).

## Code Changes

### `mix.exs`

- Add `{:rustler_precompiled, "~> 0.9"}` as a dependency
- Change `{:rustler, "~> 0.37.3"}` to `{:rustler, "~> 0.37.3", optional: true}`
- Add `checksum-*.exs` to the hex package `files` list

### `lib/postal/native.ex`

Replace `use Rustler` with `use RustlerPrecompiled`:

```elixir
defmodule Postal.Native do
  @moduledoc false

  @version Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :postal,
    crate: "postal_nif",
    base_url: "https://github.com/levibuzolic/postal/releases/download/v#{@version}",
    force_build: System.get_env("POSTAL_BUILD") in ["1", "true"],
    targets: [
      "aarch64-apple-darwin",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu"
    ],
    nif_versions: ["2.17"],
    version: @version

  # NIF stubs...
end
```

When `force_build` is true, `RustlerPrecompiled` delegates to Rustler for source compilation. The `Postal.Native.Env` module (pkg-config detection) is still needed for this path.

### `lib/postal/native/env.ex`

Kept as-is. Only used during force-build (local dev or unsupported targets).

## Workflows

### `.github/workflows/build-nifs.yml` (new)

**Trigger:** tag push `v*`

Matrix build across 4 targets. Each job:

1. Check out the repo
2. Install libpostal (brew on macOS, source build on Linux)
3. Install Rust toolchain targeting the matrix target
4. Build NIF using `philss/rustler-precompiled-action@v1`
5. Upload built binary as artifact
6. Attach binary to the GitHub release (draft)

### `.github/workflows/release.yml` (updated)

**Trigger:** release `published` (from GitHub UI)

After NIF builds are attached to the release, publishing the release triggers Hex publish:

1. Check out the repo
2. Install Elixir/Erlang via mise
3. Verify tag matches mix.exs version
4. Run `mix rustler_precompiled.download Postal.Native --all --print` to generate checksums
5. Run `mix hex.publish --yes`

No need to install libpostal or Rust in this workflow — it only downloads and checksums the pre-built binaries.

## Release Flow

1. Bump `@version` in `mix.exs`, commit, push to `main`
2. Push a tag: `git tag vX.Y.Z && git push origin vX.Y.Z`
3. Wait for **build-nifs** workflow to complete (4 binaries attached to draft release)
4. Go to GitHub Releases, edit the draft, click **Publish release**
5. **release** workflow triggers: generates checksums, publishes to Hex

The two-step approach lets you verify NIF builds succeeded before publishing to Hex.

## Updated CONTRIBUTING.md release section

Update to reflect the new two-step flow and the wait for NIF builds.

## Force-build for development

Developers working on the Rust NIF locally set `POSTAL_BUILD=1`:

```sh
POSTAL_BUILD=1 mix compile
```

This bypasses precompiled downloads and compiles from source using Rustler + pkg-config detection.

## What users need

- **With precompiled NIF (default):** Elixir, libpostal C library. No Rust needed.
- **With force-build:** Elixir, Rust toolchain, libpostal C library (headers + lib).
