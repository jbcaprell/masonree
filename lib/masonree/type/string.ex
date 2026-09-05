defmodule Masonree.Type.String do
  @moduledoc """
  Defines the `:string` member of the lattice.

  Text, and text alone. A binary is what a JSON string comes back as, and the
  member admits exactly that — so `"<strong>Hello, world!</strong>"` is
  admissible, but what it admits is the characters, not the emphasis. The
  lattice cannot tell markup from the text that spells it and does not try: text
  that carries meaning through tags would be a different member, and the lattice
  does not hold one.
  """
  @moduledoc since: "0.3.0"

  @behaviour Masonree.Type

  alias Masonree

  alias Masonree.Type

  @impl Type
  def admits?(_payload, value), do: is_binary(value)

  @impl Type
  def declarable?(payload), do: is_nil(payload)

  @impl Type
  def heal(_payload, _value, _default), do: :refused
end
