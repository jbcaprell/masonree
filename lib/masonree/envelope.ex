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

  alias Masonree

  alias Masonree.Document

  @typedoc "Represents a value handed to this type, before it is judged."
  @typedoc since: "0.4.0"
  @type input() :: term()

  @typedoc "Represents the document as a plain map, the shape jsonb stores."
  @typedoc since: "0.4.0"
  @type serialized() :: Document.serialized()

  @typedoc "Represents the database representation the adapter is given."
  @typedoc since: "0.4.0"
  @type type() :: :map

  @typedoc "Represents an envelope written, or a value that is not a document."
  @typedoc since: "0.4.0"
  @type writing() :: {:ok, serialized()} | :error

  # @impl Ecto.Type
  @doc """
  Returns `{:ok, envelope}` where `value` is a document, or `:error`.

  The envelope is `Masonree.Document.to_map/1`’s, with string keys the whole way
  down, and it is what an adapter hands to jsonb. Nothing else is accepted — a
  bare map is refused rather than passed through, because a map reaching the
  writer means a document was never built and storing it would put a shape in
  the column that the model has not seen.

  It does not validate content. A document holding an attribute no manifest
  declares goes into the column as it stands — and at this arc nothing in the
  library could judge it anyway, since conformance and reconciliation are later
  strata. An editor saves work that is half-done by construction, and a writer
  that refused it would make the database the place a draft goes to be rejected.
  Validation is a decision about whether to accept an edit, taken where the edit
  arrives; storage is a decision about bytes.

  It does refuse what the reader would refuse. Those are different questions:
  the first is about whether a document is good, the second about whether it
  is readable at all. `Masonree.Document.from_map/1` refuses an envelope holding
  a node whose `"type"` is not a string, at any depth — so a writer that did not
  ask would commit a row nothing can ever read back, and the failure would
  surface as a raise out of an adapter on some later page request rather than
  here, where the caller still has the document in hand. A writer that can
  produce a row its own reader refuses has no way to be correct, so this one
  asks; the check is the reader itself, which is what keeps the two from
  drifting apart.

  ## Examples

      iex> dump(%Document{})
      {:ok, %{"root" => []}}

      iex> dump(%{"root" => []})
      :error

  """
  @doc since: "0.4.0"
  @spec dump(input()) :: writing()
  def dump(%Document{} = value) do
    envelope = Document.to_map(value)

    case Document.from_map(envelope) do
      {:ok, _document} -> {:ok, envelope}
      :error -> :error
    end
  end

  def dump(_value), do: :error

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
