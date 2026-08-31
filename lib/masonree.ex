defmodule Masonree do
  @moduledoc """
  Defines the library’s boundary.

  `Boundary` is declared on a module, and every module the library exports is
  grouped beneath this one; that grouping is what turns a call across the
  boundary into a compile error rather than a convention someone remembers. The
  anchor carries no functions of its own, and that is the point — a namespace
  module that also held behaviour would become the drawer everything with no
  better home ends up in, and nothing here belongs to no module.

  Four dependencies are named. `Phoenix.Component` is what lets a block write
  its markup in `~H`; `Phoenix.LiveView` is where the struct that markup
  evaluates to lives; `Phoenix.HTML` is the protocol that turns it into bytes;
  and `Ecto.Type` is the behaviour a column’s type implements. All four are
  named rather than left implicit, because naming one module of an application
  is what makes every other call into it a compile error — a boundary that
  admits whatever the deps list happens to hold is a boundary in name only.

  Nothing is exported yet, because nothing outside this library has shown a
  need for a name, and an export that anticipates a caller is an export
  nobody can retire.
  """
  @moduledoc since: "0.1.0"

  use Boundary,
    deps: [
      Ecto.Type,
      Phoenix.Component,
      Phoenix.HTML,
      Phoenix.LiveView
    ]
end
