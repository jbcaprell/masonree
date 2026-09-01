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

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute

  @enforce_keys [:name, :version]
  defstruct attributes: %{}, category: nil, label: nil, name: nil, version: nil

  @typedoc "Represents an attribute’s key in the manifest."
  @typedoc since: "0.3.0"
  @type key() :: String.t()

  @typedoc "Represents the block’s name."
  @typedoc since: "0.3.0"
  @type name() :: String.t()

  @typedoc "Represents the owning half of a namespaced name."
  @typedoc since: "0.5.0"
  @type namespace() :: String.t()

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          attributes: %{key() => Attribute.t()},
          category: nil | String.t(),
          label: nil | String.t(),
          name: name(),
          version: version()
        }

  @typedoc "Represents the block’s version, a count of its migrations."
  @typedoc since: "0.3.0"
  @type version() :: pos_integer()

  @doc """
  Returns the namespace of `name`, or `nil` where it carries none.

  A name is namespaced only when a single `/` splits it into two non-empty
  halves. The reading is deliberately tolerant: this question is also asked
  about `type` strings read out of stored content, which never passed through
  any judgment, so it answers about any binary rather than assuming a
  well-formed one.

  ## Examples

      iex> get_namespace("core/paragraph")
      "core"

      iex> get_namespace("example")
      nil

  """
  @doc since: "0.5.0"
  @spec get_namespace(name()) :: nil | namespace()
  def get_namespace(name) when is_binary(name) do
    name
    |> String.split("/")
    |> take_namespace()
  end

  @spec take_namespace([String.t()]) :: nil | namespace()
  defp take_namespace([namespace, local_name])
       when namespace != "" and local_name != "" do
    namespace
  end

  defp take_namespace(_parts), do: nil
end
