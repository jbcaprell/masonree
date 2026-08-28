defmodule Masonree.MixProject do
  @moduledoc "Defines a `Mix.Project` project."
  @moduledoc since: "0.1.0"

  use Mix.Project

  @typedoc "Represents the project configuration."
  @typedoc since: "0.1.0"
  @type project() :: [project_keyword()]

  @typep project_keyword() ::
           {:app, Application.app()}
           | {:version, String.t()}
           | {Keyword.key(), Keyword.value()}

  @doc """
  Returns the project configuration.

  ## Example

      iex> project()[:app]
      :masonree

  """
  @doc since: "0.1.0"
  @spec project() :: project()
  def project() do
    [
      aliases: [
        "boundary.ex_doc_groups": [
          "boundary.ex_doc_groups",
          &write_moduledoc_group/1,
          "format .boundary.exs"
        ],
        credo: "credo --config-name default"
      ],
      app: :masonree,
      boundary: [default: [type: :strict]],
      compilers: [:boundary | Mix.compilers()],
      deps: [
        {:boundary, "~> 0.10", runtime: false},
        {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
        {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
      ],
      deps_path: "dep",
      dialyzer: [ignore_warnings: ".dialyzer.exs"],
      elixir: "~> 1.20",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

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
