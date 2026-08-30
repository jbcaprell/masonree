defmodule Masonree.Type.Number do
  @moduledoc """
  Defines the `:number` member of the lattice.

  Integer or float, undivided. The lattice draws no line between them because
  nothing it sits between draws one: `JSON`, `jsonb`, and the browser carry a
  single numeric type each, and a member that split them would be the only thing
  in the stack that did. A block needing a bounded whole number says so with an
  enum — `{:enum, [1, 2, 3]}` refuses `2.5` and `9` alike.
  """
  @moduledoc since: "0.3.0"

  @behaviour Masonree.Type

  alias Masonree

  alias Masonree.Type

  @impl Type
  def admits?(_payload, value), do: is_number(value)
end
