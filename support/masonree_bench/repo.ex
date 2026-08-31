defmodule MasonreeBench.Repo do
  @moduledoc """
  Defines the `Ecto.Repo` the suite reads and writes documents through.

  The connection is assembled in `init/2` rather than read from a config file,
  because this project has no `config/` directory and a database used by one
  suite does not earn one. Every value has a default and an environment variable
  that overrides it, so the gate’s new precondition can be stated in one line —
  a Postgres is running, and these five variables reach it — rather than as a
  file someone has to edit.

  The pool is `Ecto.Adapters.SQL.Sandbox`, so the tests that touch it stay
  `async: true` and no test sees another’s rows.

  `log: false`, because a suite’s evidence is its assertions and a repo that
  narrated every statement would put forty lines of SQL between the gate and the
  count it prints.
  """
  @moduledoc since: "0.4.0"

  use Ecto.Repo, adapter: Ecto.Adapters.Postgres, otp_app: :masonree

  alias Ecto

  alias Ecto.Adapters

  alias Adapters.SQL

  alias SQL.Sandbox

  @typedoc "Represents the confirmation Ecto asks for."
  @typedoc since: "0.4.0"
  @type answer() :: {:ok, configuration()}

  @typedoc "Represents the connection this suite runs against."
  @typedoc since: "0.4.0"
  @type configuration() :: Keyword.t()

  @typedoc "Represents when the repo is asked what it connects to."
  @typedoc since: "0.4.0"
  @type context() :: :runtime | :supervisor

  @impl Ecto.Repo
  @doc """
  Returns `{:ok, configuration}`, the connection this suite runs against.

  `context` is `:supervisor` when the repo starts and `:runtime` when `config/0`
  is asked, and the answer is the same either way: the repo has one connection
  and no per-context variation to express.
  """
  @doc since: "0.4.0"
  @spec init(context(), configuration()) :: answer()
  def init(_context, configuration) do
    connection = [
      database: System.get_env("MASONREE_BENCH_DATABASE", "masonree_bench"),
      hostname: System.get_env("MASONREE_BENCH_HOSTNAME", "localhost"),
      log: false,
      password: System.get_env("MASONREE_BENCH_PASSWORD", "postgres"),
      pool: Sandbox,
      pool_size: System.schedulers_online() * 2,
      port: get_port(),
      username: System.get_env("MASONREE_BENCH_USERNAME", "postgres")
    ]

    {:ok, Keyword.merge(configuration, connection)}
  end

  @spec get_port() :: pos_integer()
  defp get_port() do
    "MASONREE_BENCH_PORT"
    |> System.get_env("5432")
    |> String.to_integer()
  end
end
