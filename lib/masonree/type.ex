defmodule Masonree.Type do
  @moduledoc """
  Defines the lattice an attribute’s type is drawn from.

  A member of the lattice is a module, and it answers a single question: whether
  a value is admissible under it. Some members are declared with a payload that
  shapes what they admit and some with nothing at all; the question is put the
  same way to both.

  The set is closed. A member is a module in this library implementing this
  behaviour, so the members are fixed when the library compiles — no caller, no
  configuration and no stored value adds one.
  """
  @moduledoc since: "0.3.0"

  @typedoc "Represents the payload a member is declared with."
  @typedoc since: "0.3.0"
  @type payload() :: term()

  @typedoc "Represents the value a member is asked about."
  @typedoc since: "0.3.0"
  @type value() :: term()

  @doc "Returns whether `value` is admissible under this member’s `payload`."
  @doc since: "0.3.0"
  @callback admits?(payload :: payload(), value :: value()) :: boolean()
end
