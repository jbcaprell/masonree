defmodule MasonreeBench.Page do
  @moduledoc """
  Defines the `Ecto.Schema` a document is stored in.

  The library claims a document survives a database, and nothing in `Masonree`
  can put one there. This is the row that lets the claim be tested — somewhere a
  real document can be written to and read back from, so that the round trip is
  performed by Ecto and Postgres rather than by a test calling four functions in
  order and checking their arithmetic.

  It is the least schema that can hold a document. One column, no identity and
  no metadata: a bench row is made, read once and thrown away, and nothing
  fetches, updates or deletes it by key because nothing needs to. Anything more
  would be a claim about a platform’s table that this library has no business
  making — a real one carries a site, a path, a status and its own timestamps,
  and this one stands in for it and resembles it no further.

  Declaring `body` as `Masonree.Envelope` is the whole of the fixture’s work.
  That one line is what a platform writes to make this library’s documents
  persist, and writing it here is what puts the library’s own type on the path a
  real insert and a real query take.
  """
  @moduledoc since: "0.4.0"

  use Ecto.Schema

  alias Masonree

  alias Masonree.Document
  alias Masonree.Envelope

  @typedoc "Represents the row a document is stored as."
  @typedoc since: "0.4.0"
  @type t() :: %__MODULE__{body: nil | Document.t()}

  @primary_key false
  schema "page" do
    field :body, Envelope
  end
end
