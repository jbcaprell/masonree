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
      app: :masonree,
      elixir: "~> 1.20",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end
end
