defmodule Postal.Native do
  @moduledoc false

  @libpostal_env Postal.Native.Env.build()

  use Rustler,
    otp_app: :postal,
    crate: "postal_nif",
    env: @libpostal_env

  @spec setup() :: :ok | {:error, String.t()}
  def setup, do: :erlang.nif_error(:nif_not_loaded)

  @spec parse_address(String.t()) :: {:ok, [{String.t(), String.t()}]} | {:error, String.t()}
  def parse_address(_address), do: :erlang.nif_error(:nif_not_loaded)

  @spec expand_address(String.t(), [String.t()]) :: {:ok, [String.t()]} | {:error, String.t()}
  def expand_address(_address, _languages), do: :erlang.nif_error(:nif_not_loaded)
end
