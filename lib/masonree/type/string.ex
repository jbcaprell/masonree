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

  @typedoc "What a healing moves toward: the attribute’s declared default."
  @typedoc since: "0.8.0"
  @type default() :: Type.default()

  @typedoc "Represents a member’s answer about a value it refused."
  @typedoc since: "0.8.0"
  @type healing() :: Type.healing()

  @typedoc "Represents the payload a member is declared with."
  @typedoc since: "0.8.0"
  @type payload() :: Type.payload()

  @typedoc "Represents the value a member is asked about."
  @typedoc since: "0.8.0"
  @type value() :: Type.value()

  # @impl Type
  @doc false
  @spec heal(payload(), value(), default()) :: healing()
  def heal(_payload, _value, _default), do: :refused

  @impl Type
  def admits?(_payload, value), do: is_binary(value)

  @impl Type
  def declarable?(payload), do: is_nil(payload)
end
