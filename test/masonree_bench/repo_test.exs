defmodule MasonreeBench.RepoTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: false

  alias Ecto
  alias MasonreeBench

  alias Ecto.Adapters
  alias MasonreeBench.Repo

  alias Adapters.SQL

  alias SQL.Sandbox

  describe "init/2" do
    import Repo, only: [init: 2]

    test "answers the same for a supervisor as for a runtime caller" do
      assert init(:supervisor, []) == init(:runtime, [])
    end

    test "keeps the sandbox pool, so a test sees none of another’s rows" do
      {:ok, configuration} = init(:runtime, [])

      assert configuration[:pool] == Sandbox
    end

    test "keeps what Ecto supplies and wins where the two disagree" do
      supplied = [otp_app: :masonree, pool_size: 10, timeout: 15_000]

      {:ok, configuration} = init(:runtime, supplied)

      assert configuration[:otp_app] == :masonree
      assert configuration[:timeout] == 15_000
      assert configuration[:pool_size] == System.schedulers_online() * 2
    end

    test "reads every connection value from the environment" do
      on_exit(fn ->
        System.delete_env("MASONREE_BENCH_DATABASE")
        System.delete_env("MASONREE_BENCH_PORT")
      end)

      System.put_env("MASONREE_BENCH_DATABASE", "bench_probe")
      System.put_env("MASONREE_BENCH_PORT", "5555")

      {:ok, configuration} = init(:runtime, [])

      assert {configuration[:database], configuration[:port]} ==
               {"bench_probe", 5_555}
    end

    test "silences the log, so the gate prints a count and not SQL" do
      {:ok, configuration} = init(:runtime, [])

      refute configuration[:log]
    end

    test "takes the environment’s defaults when nothing overrides them" do
      {:ok, configuration} = init(:runtime, [])

      assert {configuration[:database], configuration[:hostname],
              configuration[:port]} == {"masonree_bench", "localhost", 5_432}
    end
  end
end
