defmodule Masonree.MixProject do
  @moduledoc "Defines a `Mix.Project` project."
  @moduledoc since: "0.1.0"

  use Mix.Project

  @typedoc "Represents the application configuration."
  @typedoc since: "0.3.0"
  @type application() :: [{Keyword.key(), Keyword.value()}]

  @typedoc "Represents the project configuration."
  @typedoc since: "0.1.0"
  @type project() :: [project_keyword()]

  @typep env() :: :dev | :prod | :test | atom()

  @typep project_keyword() ::
           {:app, Application.app()}
           | {:version, String.t()}
           | {Keyword.key(), Keyword.value()}

  @doc """
  Returns the application configuration.

  ## Example

      iex> application()[:extra_applications]
      [:crypto, :logger]

  """
  @doc since: "0.3.0"
  @spec application() :: application()
  def application(), do: [extra_applications: ~W[crypto logger]a]

  @doc """
  Returns the project configuration.

  ## Example

      iex> project()[:app]
      :masonree

  """
  @doc since: "0.1.0"
  @spec project() :: project()
  def project() do
    env = Mix.env()

    [
      aliases: [
        "boundary.ex_doc_groups": [
          "boundary.ex_doc_groups",
          &write_moduledoc_group/1,
          "format .boundary.exs"
        ],
        credo: "credo --config-name default",
        docs: ["boundary.ex_doc_groups", "docs"]
      ],
      app: :masonree,
      boundary: [default: [type: :strict]],
      compilers: [:boundary | Mix.compilers()],
      deps: [
        {:boundary, "~> 0.10", runtime: false},
        {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
        {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
        {:ecto, "~> 3.13"},
        {:ecto_sql, "~> 3.13", only: [:dev, :test]},
        {:ex_doc, "~> 0.40", only: :dev, runtime: false},
        {:phoenix_live_view, "~> 1.2"},
        {:postgrex, "~> 0.21", only: [:dev, :test]}
      ],
      deps_path: "dep",
      dialyzer: [ignore_warnings: ".dialyzer.exs"],
      docs: [groups_for_modules: load_moduledoc_group(env)],
      elixir: "~> 1.20",
      elixirc_options: [warnings_as_errors: true],
      elixirc_paths: get_elixirc_path(env),
      name: "Masonree",
      start_permanent: env == :prod,
      test_coverage: [ignore_modules: [~r/\AMasonreeBench(\.|\z)/]],
      version: "0.5.2"
    ]
  end

  @spec get_elixirc_path(env()) :: [Path.t()]
  defp get_elixirc_path(:dev), do: get_elixirc_path(:test)
  defp get_elixirc_path(:test), do: ["support" | get_elixirc_path(:prod)]
  defp get_elixirc_path(env) when is_atom(env), do: ["lib"]

  @spec load_moduledoc_group(env()) :: nil | Keyword.t([module()])
  defp load_moduledoc_group(:dev) do
    ".boundary.exs"
    |> Code.eval_file()
    |> elem(0)
  end

  defp load_moduledoc_group(env) when is_atom(env), do: nil

  @spec write_moduledoc_group(OptionParser.argv()) :: :ok
  defp write_moduledoc_group(_argv) do
    "boundary.exs"
    |> Code.eval_file()
    |> elem(0)
    |> Macro.escape()
    |> Macro.to_string()
    |> then(&File.write!(".boundary.exs", &1))

    File.rm!("boundary.exs")
  end
end
