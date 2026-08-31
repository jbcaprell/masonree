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

  The export list is a record of observed need and not a published API. It grows
  in the commit where something outside is shown to require a name, and never in
  advance of one. `Masonree.Envelope` is the first, because a schema outside
  this boundary declares a column as it. Nothing in the compiler finds that
  dependency, so the entry is the only record of it.
  """
  @moduledoc since: "0.1.0"

  use Boundary,
    deps: [
      Ecto.Type,
      Phoenix.Component,
      Phoenix.HTML,
      Phoenix.LiveView
    ],
    exports: [Envelope]
end
