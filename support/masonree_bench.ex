defmodule MasonreeBench do
  @moduledoc """
  Defines the apparatus the library is measured on.

  Everything beneath this module exists so that a test can put a document in a
  real column and read it back out. A library that claims a document survives
  storage has to store one, and nothing in `Masonree` can: the library names
  `Ecto.Type` and nothing else of Ecto, so a repo written inside it would
  not compile.

  That refusal is the design working, and it is why the apparatus is a second
  boundary rather than a corner of the first. What a library is measured on may
  own a connection; the library may not, and the compiler is where the
  difference is kept rather than in a comment. The name is a sibling for the
  same reason — a boundary nested under `Masonree` could depend only on what
  `Masonree` already depends on, which is the same refusal reached from the
  other side.
  """
  @moduledoc since: "0.4.0"

  use Boundary,
    deps: [
      Ecto.Adapters.Postgres,
      Ecto.Adapters.SQL,
      Ecto.Multi,
      Ecto.Query,
      Ecto.Repo,
      Ecto.Schema,
      Masonree
    ]
end
