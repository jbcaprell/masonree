defmodule Masonree.Manifest do
  @moduledoc """
  Defines what a block declares about itself.

  A manifest carries a block’s name, its version, how it announces itself in an
  editor, and the attributes whose values a node of that type may hold. It is
  the whole of what a block knows about itself: anything needing a second block
  to answer belongs elsewhere, which is what lets a manifest be checked at its
  own compile.

  Only `attributes` describes anything a node stores. A node’s `attributes` hold
  values whose meaning is fixed here; the rest is code. `label` and `category`
  are display and may be reworded freely; an attribute cannot, because changing
  one orphans stored content.

  A version belongs to the block rather than to the library: it counts the
  migrations a node of this type may have to walk. It is 1 until the block’s
  stored shape first moves.

  ## Example

      iex> %Manifest{name: "test/example", version: 1}
      %Manifest{
        attributes: %{},
        category: nil,
        label: nil,
        name: "test/example",
        version: 1
      }

  """
  @moduledoc since: "0.3.0"

  @enforce_keys [:name, :version]
  defstruct attributes: %{}, category: nil, label: nil, name: nil, version: nil

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          attributes: %{String.t() => map()},
          category: nil | String.t(),
          label: nil | String.t(),
          name: String.t(),
          version: pos_integer()
        }
end
