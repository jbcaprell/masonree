defmodule Masonree.Type do
  @moduledoc """
  Defines the lattice an attribute’s type is drawn from.

  A member of the lattice is a module, and it answers for itself: whether a
  value is admissible under it, and whether a declaration of it is well formed
  at all. Some members are declared with a payload that shapes what they admit
  and some with nothing at all; a question is put the same way to both.

  The set is closed. A member is a module in this library implementing this
  behaviour, so the members are fixed when the library compiles — no caller, no
  configuration and no stored value adds one.

  The lattice is asked `admits?/2` with a type and a value; it resolves the type
  to a member and asks that member `c:admits?/2`, handing it the payload the
  type carried and the same value. It is asked `declarable?/1` with a type
  alone, before any value exists, and resolves it the same way — a type that
  resolves to no member is not declarable, and admits nothing.
  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Type

  @typedoc "Represents a type as a manifest declares it, before it is judged."
  @typedoc since: "0.5.0"
  @type declaration() :: term()

  @typedoc "Represents the payload a member is declared with."
  @typedoc since: "0.3.0"
  @type payload() :: term()

  @typedoc "Represents a type, with the payload where its member takes one."
  @typedoc since: "0.3.0"
  @type t() :: :boolean | :number | :string | {:enum, [value()]}

  @typedoc "Represents the name of a member."
  @typedoc since: "0.3.0"
  @type tag() :: :boolean | :enum | :number | :string

  @typedoc "Represents every tag the lattice holds, sorted."
  @typedoc since: "0.3.0"
  @type tags() :: [tag()]

  @typedoc "Represents the value a member is asked about."
  @typedoc since: "0.3.0"
  @type value() :: term()

  @doc "Returns whether `value` is admissible under this member’s `payload`."
  @doc since: "0.3.0"
  @callback admits?(payload :: payload(), value :: value()) :: boolean()

  @doc "Returns whether this member may be declared with `payload`."
  @doc since: "0.5.0"
  @callback declarable?(payload :: payload()) :: boolean()

  @modules %{
    boolean: Type.Boolean,
    enum: Type.Enum,
    number: Type.Number,
    string: Type.String
  }

  @doc """
  Returns whether `type` may hold `value`.

  A `nil` is admitted by every member: an absent value is not a wrong one,
  and refusing it here would make every optional attribute a fault.

  ## Examples

      iex> admits?(:boolean, true)
      true

      iex> admits?(:boolean, "true")
      false

      iex> admits?({:enum, ["dark", "light"]}, "dark")
      true

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

  @doc """
  Returns whether `type` may be declared at all.

  A different question from `admits?/2`, asked at a different moment: this one
  judges the declaration a block author wrote, before any value exists. A scalar
  member is declarable bare and only bare — `{:boolean, []}` carries a payload
  where none belongs — and an enum is declarable exactly when its payload is a
  list. What a well-shaped payload must contain is not answered here: whether
  an enum’s list is empty, or repeats itself, is a rule about a usable
  declaration rather than a legible one, and it belongs to the module that
  judges declarations.

  ## Examples

      iex> declarable?(:boolean)
      true

      iex> declarable?({:boolean, []})
      false

      iex> declarable?({:enum, ["dark", "light"]})
      true

      iex> declarable?(:bool)
      false

  """
  @doc since: "0.5.0"
  @spec declarable?(declaration()) :: boolean()
  def declarable?(type) do
    case resolve(type) do
      {module, payload} -> module.declarable?(payload)
      :error -> false
    end
  end

  @doc """
  Returns the tags the lattice holds, sorted.

  The one place that names the set. Anything needing to know the members asks
  here rather than keeping a list of its own, so a member joins the lattice once
  and is known everywhere.

  ## Example

      iex> list_tags()
      [:boolean, :enum, :number, :string]

  """
  @doc since: "0.3.0"
  @spec list_tags() :: tags()
  def list_tags() do
    @modules
    |> Map.keys()
    |> Enum.sort()
  end

  @spec resolve(t()) :: :error | {module(), payload()}
  defp resolve({tag, payload}) when is_atom(tag) do
    case Map.fetch(@modules, tag) do
      {:ok, module} -> {module, payload}
      :error -> :error
    end
  end

  defp resolve(type) when is_atom(type) do
    case Map.fetch(@modules, type) do
      {:ok, module} -> {module, nil}
      :error -> :error
    end
  end

  defp resolve(_type), do: :error
end
