defmodule Masonree.Type.Boolean do
  @moduledoc """
  Defines the `:boolean` member of the lattice.

  A flag, and nothing else: `true` or `false`, never `"true"`, and never `1`. A
  type that admitted a string here would make every reader of a stored value
  guess which spelling produced it.
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
  def admits?(_payload, value), do: is_boolean(value)

  @impl Type
  def declarable?(payload), do: is_nil(payload)
end
