defmodule Postal.Native.Env do
  @moduledoc false

  @doc false
  def build do
    env = []

    env =
      case pkg_config("--cflags") do
        {:ok, cflags} -> [{"BINDGEN_EXTRA_CLANG_ARGS", cflags} | env]
        :error -> env
      end

    case pkg_config("--libs-only-L") do
      {:ok, libs} ->
        rustflags = System.get_env("RUSTFLAGS", "")
        [{"RUSTFLAGS", "#{rustflags} #{libs}"} | env]

      :error ->
        env
    end
  end

  defp pkg_config(flag) do
    case System.cmd("pkg-config", [flag, "libpostal"], stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.trim(output)}
      _ -> :error
    end
  end
end
