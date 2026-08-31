alias Ecto
alias MasonreeBench

alias Ecto.Adapters
alias MasonreeBench.Repo

alias Adapters.SQL

alias SQL.Sandbox

table =
  """
  CREATE TABLE IF NOT EXISTS page (
    body jsonb NOT NULL
  )
  """

shape =
  """
  SELECT data_type
    FROM information_schema.columns
    WHERE table_name = 'page' AND column_name = 'body'
  """

configuration = Repo.config()

case Repo.__adapter__().storage_up(configuration) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  {:error, reason} -> raise "the database is unreachable: #{inspect(reason)}"
end

{:ok, _pid} = Repo.start_link()

SQL.query!(Repo, table, [])

case SQL.query!(Repo, shape, []).rows do
  [["jsonb"]] -> :ok
  [[found]] -> raise "the table is stale: page.body is #{found}, not jsonb"
  [] -> raise "the table is stale: page has no body column"
end

Sandbox.mode(Repo, :manual)

ExUnit.start()
