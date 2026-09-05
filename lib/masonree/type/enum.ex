defmodule Masonree.Type.Enum do
  @moduledoc """
  Defines the `{:enum, values}` member of the lattice.

  The payload is the list of values admitted, and membership is the whole rule:
  a value is admissible when the list holds it, and not otherwise. The
  comparison is identity, so `"dark"` and `:dark` are two values and an enum
  declared with one does not admit the other.

  The list need not be homogeneous. An enum has no base type for the list to
  disagree with, so `[1, 2, 3, "auto"]` is a single declaration rather than a
  number carrying an exception. A payload that is not a list admits nothing, and
  that includes the `nil` a bare `:enum` carries.
  """
  @moduledoc since: "0.3.0"

  @behaviour Masonree.Type

  alias Masonree

  alias Masonree.Type

  @impl Type
  def admits?(payload, value) when is_list(payload), do: value in payload
  def admits?(_payload, _value), do: false

  @impl Type
  def declarable?(payload), do: is_list(payload)

  @impl Type
  def heal(_payload, _value, default), do: {:coerced, default}
end
