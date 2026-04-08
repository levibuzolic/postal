defmodule Postal.Native do
  @moduledoc false

  alias Postal.Native.Env

  @version Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :postal,
    crate: "postal_nif",
    base_url: "https://github.com/levibuzolic/postal/releases/download/v#{@version}",
    force_build: System.get_env("POSTAL_BUILD") in ["1", "true"],
    targets: [
      "aarch64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu"
    ],
    nif_versions: ["2.17"],
    version: @version,
    env: Env.build()

  @spec setup() :: :ok | {:error, String.t()}
  def setup, do: :erlang.nif_error(:nif_not_loaded)

  @spec parse_address(String.t()) :: {:ok, [{String.t(), String.t()}]} | {:error, String.t()}
  def parse_address(_address), do: :erlang.nif_error(:nif_not_loaded)

  @spec expand_address(String.t(), [String.t()]) :: {:ok, [String.t()]} | {:error, String.t()}
  def expand_address(_address, _languages), do: :erlang.nif_error(:nif_not_loaded)
end
