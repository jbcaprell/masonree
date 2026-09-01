defmodule Masonree.Manifest.Attribute do
  @moduledoc """
  Defines one attribute of a block.

  An attribute declares a type, a default, and whether a value is mandatory. Its
  key is the key of the map that holds it — a name on the struct as well would
  be a second place for a name to live and disagree. An attribute is the only
  part of a manifest that fixes the meaning of stored values, and every field
  here is contract.

  The type is drawn from `Masonree.Type`’s lattice, and this struct holds no
  opinion of its own about what a member admits: a new member widens
  `Masonree.Type.t()` and not this struct.

  `required: true` means no honest default exists. Requiredness governs absence,
  a default fills absence, and declaring both is a contradiction. It is a rule
  of the declaration and not of this struct, which accepts the pair; refusing it
  is a validator’s work.

  `role` says whether the attribute is content — what the page says — or chrome
  — how it presents. Nothing mechanical can tell a headline from a layout flag,
  so the author declares the side, and the declaration is contract: which half
  of a node a sealed container leaves editable hangs on exactly this field. It
  defaults to `nil` only so a struct can be built a field at a time; an
  undeclared role is a fault of the declaration, and the rule that refuses it
  belongs to a validator rather than to this struct.

  ## Examples

      iex> %Attribute{required: true, role: :content, type: :string}
      %Attribute{
        default: nil,
        required: true,
        role: :content,
        type: :string
      }

      iex> %Attribute{default: 1, role: :chrome, type: {:enum, [1, 2, 3]}}
      %Attribute{
        default: 1,
        required: false,
        role: :chrome,
        type: {:enum, [1, 2, 3]}
      }

  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Type

  @enforce_keys [:type]
  defstruct default: nil, required: false, role: nil, type: nil

  @typedoc "Represents the attribute declaration."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          default: nil | value(),
          required: boolean(),
          role: nil | :chrome | :content,
          type: Type.t()
        }

  @typedoc "Represents a value an attribute can hold."
  @typedoc since: "0.3.0"
  @type value() :: boolean() | number() | String.t()
end
