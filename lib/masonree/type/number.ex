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
  def admits?(_payload, value), do: is_number(value)

  @impl Type
  def declarable?(payload), do: is_nil(payload)
end
