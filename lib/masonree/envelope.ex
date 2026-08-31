defmodule Masonree.Envelope do
  @moduledoc """
  Defines the `Ecto.Type` a stored document is a column of.

  A page persists as a tree the database can index and query rather than as
  markup it would have to parse, and this module is the whole of what that costs
  a platform: one name a schema declares a field as, standing between
  `Masonree.Document` and the column that holds it.

  It names no repo, opens no connection and writes no migration — whose database
  a page lives in, what the column is called and what else the row carries are
  the platform’s decisions, and a library that made them would be a framework.
  What is here is the one piece a platform cannot write for itself, because it
  is the only piece that has to know the document’s shape.
  """
  @moduledoc since: "0.4.0"

  @typedoc "Represents the database representation the adapter is given."
  @typedoc since: "0.4.0"
  @type type() :: :map

  # @impl Ecto.Type
  @doc """
  Returns `:map`, the database representation.

  The adapter chooses `json` or `jsonb` from the column, and the choice is the
  platform’s — a GIN index over a `jsonb` column is what answers which pages use
  this block, and this library does not own the index either.

  ## Example

      iex> type()
      :map

  """
  @doc since: "0.4.0"
  @spec type() :: type()
  def type(), do: :map
end
