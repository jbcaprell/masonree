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

  @typedoc "Represents a document read, or a shape that is not one."
  @typedoc since: "0.4.0"
  @type reading() :: Document.reading()

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
  Returns `{:ok, document}` where `value` is a document or an envelope.

  A document passes through untouched, which is the path a caller takes when
  the tree is already built — the ordinary case, since edits are made against
  `Masonree.Document`’s own operations and the result is cast, not parsed.

  A map is read as an envelope, so a document arriving as parameters — a JSON
  request body, a form that carries the tree whole — is accepted without the
  caller reaching for the reader itself. It is the same read `load/1` performs
  and refuses the same shapes, because a value that could not have come out of
  the column has no business going into it.

  Everything else is `:error`, including a keyword list and a struct that is
  not a document: this module has one representation and does not guess at
  another.

  ## Examples

      iex> cast(%Document{})
      {:ok, %Document{root: []}}

      iex> cast(%{"root" => []})
      {:ok, %Document{root: []}}

      iex> cast("{}")
      :error

  """
  @doc since: "0.4.0"
  @spec cast(input()) :: reading()
  def cast(%Document{} = value), do: {:ok, value}
  def cast(value) when is_map(value), do: Document.from_map(value)
  def cast(_value), do: :error

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
  Returns `{:ok, document}` where `value` is an envelope, or `:error`.

  This is the path out of the database and the reason
  `Masonree.Document.from_map/1` exists. It fills every absence a stored
  envelope may carry and refuses only a root entry that is not a node, at any
  depth — and refuses the page rather than the entry, because a page returned
  with one subtree missing is worse than one not returned at all.

  It never raises, and that is not a preference. A reader on this path is called
  on every row that comes back, so a raise would take down a query over a page
  nobody was asking about. `Masonree.Document.from_map/1` is the answering
  sibling minted one arc ago for exactly this consumer, before the consumer
  existed.

  Nor does it migrate. Stepping a stored node forward needs a blocks map, and a
  caller on this path has no way to reach one — the value is all it is handed.
  Where the two walks a loaded page owes are composed is a later arc’s subject,
  and this function’s work ends at the struct.

  A `nil` column is not a document and is not tolerated. A schema that wants an
  absent page should say so with a nullable field the caller branches on rather
  than by handing this function an emptiness to interpret.

  ## Examples

      iex> envelope = %{
      ...>   "root" => [%{"id" => "n_fQnwiIJkHCwf", "type" => "test/example"}]
      ...> }
      iex>
      iex> load(envelope)
      {
        :ok,
        %Document{
          root: [%Node{id: "n_fQnwiIJkHCwf", type: "test/example", version: 1}]
        }
      }

      iex> load([])
      :error

  """
  @doc since: "0.4.0"
  @spec load(input()) :: reading()
  def load(value) when is_map(value), do: Document.from_map(value)
  def load(_value), do: :error

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
