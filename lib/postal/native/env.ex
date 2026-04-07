defmodule Postal.Native.Env do
  @moduledoc false

  # Common libpostal installation paths to check when pkg-config is unavailable
  @fallback_include_paths [
    "/opt/homebrew/include",
    "/usr/local/include",
    "/usr/include"
  ]

  @fallback_lib_paths [
    "/opt/homebrew/lib",
    "/usr/local/lib",
    "/usr/lib"
  ]

  @doc false
  def build do
    case pkg_config_env() do
      {:ok, env} -> env
      :error -> fallback_env()
    end
  end

  defp pkg_config_env do
    with {:ok, cflags} <- pkg_config("--cflags"),
         {:ok, libs} <- pkg_config("--libs-only-L") do
      env = [{"BINDGEN_EXTRA_CLANG_ARGS", cflags}]

      rustflags = System.get_env("RUSTFLAGS", "")
      {:ok, [{"RUSTFLAGS", "#{rustflags} #{libs}"} | env]}
    end
  end

  defp fallback_env do
    env = []

    env =
      case find_header_path() do
        {:ok, path} -> [{"BINDGEN_EXTRA_CLANG_ARGS", "-I#{path}"} | env]
        :error -> env
      end

    case find_lib_path() do
      {:ok, path} ->
        rustflags = System.get_env("RUSTFLAGS", "")
        [{"RUSTFLAGS", "#{rustflags} -L#{path}"} | env]

      :error ->
        env
    end
  end

  defp find_header_path do
    Enum.find_value(@fallback_include_paths, :error, fn path ->
      if File.exists?(Path.join(path, "libpostal/libpostal.h")),
        do: {:ok, path}
    end)
  end

  defp find_lib_path do
    Enum.find_value(@fallback_lib_paths, :error, fn path ->
      if File.exists?(Path.join(path, "libpostal.so")) or
           File.exists?(Path.join(path, "libpostal.dylib")) or
           File.exists?(Path.join(path, "libpostal.a")),
         do: {:ok, path}
    end)
  end

  defp pkg_config(flag) do
    if System.find_executable("pkg-config") do
      case System.cmd("pkg-config", [flag, "libpostal"], stderr_to_stdout: true) do
        {output, 0} -> {:ok, String.trim(output)}
        _ -> :error
      end
    else
      :error
    end
  end
end
