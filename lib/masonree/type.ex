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

  The lattice is asked `admits?/2` with a type and a value; it resolves the type
  to a member and asks that member `c:admits?/2`, handing it the payload the
  type carried and the same value.
  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Type

  @typedoc "Represents the payload a member is declared with."
  @typedoc since: "0.3.0"
  @type payload() :: term()

  @typedoc "Represents a type."
  @typedoc since: "0.3.0"
  @type t() :: :boolean

  @typedoc "Represents the value a member is asked about."
  @typedoc since: "0.3.0"
  @type value() :: term()

  @doc "Returns whether `value` is admissible under this member’s `payload`."
  @doc since: "0.3.0"
  @callback admits?(payload :: payload(), value :: value()) :: boolean()

  @modules %{boolean: Type.Boolean}

  @doc """
  Returns whether `type` may hold `value`.

  A `nil` is admitted by every member: an absent value is not a wrong one,
  and refusing it here would make every optional attribute a fault.

  ## Examples

      iex> admits?(:boolean, true)
      true

      iex> admits?(:boolean, "true")
      false

      iex> admits?(:boolean, nil)
      true

  """
  @doc since: "0.3.0"
  @spec admits?(t(), value()) :: boolean()
  def admits?(_type, nil), do: true

  def admits?(type, value) do
    case resolve(type) do
      {module, payload} -> module.admits?(payload, value)
      :error -> false
    end
  end

  @spec resolve(t()) :: :error | {module(), payload()}
  defp resolve(type) when is_atom(type) do
    case Map.fetch(@modules, type) do
      {:ok, module} -> {module, nil}
      :error -> :error
    end
  end

  defp resolve(_type), do: :error
end
