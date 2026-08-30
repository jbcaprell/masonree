defmodule Masonree.Node do
  @moduledoc """
  Defines one instance of a block in a document.

  A node names the block it instantiates, the version of that block it was
  written at, the preset that governs it, the values its attributes hold, and
  the nodes inside it. A document is a tree of these and nothing else, which is
  what lets the tree be the only thing in a database.

  `attributes` holds values whose meaning `Masonree.Manifest` declares — one
  concept in two aspects, sharing a key space. It is the only field holding
  authored content: `type`, `version` and `preset` name code, and `children` is
  structure.

  An `id` is minted, never derived from content. A derived id renumbers a page
  on any edit, which breaks selection, undo, and pattern capture. Stability
  across edits is the whole of what an id is for.

  A node carries no manifest and cannot validate itself: whether its attributes
  conform is a question about a second module, and nothing in this library asks
  it yet.

  ## Example

      iex> %Node{id: "n_5FDHUoovXjp8", type: "test/example", version: 1}
      %Node{
        attributes: %{},
        children: [],
        id: "n_5FDHUoovXjp8",
        preset: nil,
        type: "test/example",
        version: 1
      }

  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute

  @enforce_keys [:id, :type, :version]
  defstruct attributes: %{},
            children: [],
            id: nil,
            preset: nil,
            type: nil,
            version: nil

  @typedoc "Represents the node’s identity, stable across every edit."
  @typedoc since: "0.3.0"
  @type id() :: String.t()

  @typedoc "Represents the node as a plain map, the shape that persists."
  @typedoc since: "0.3.0"
  @type serialized() :: %{String.t() => term()}

  @typedoc "Represents the node."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          attributes: %{Manifest.key() => Attribute.value()},
          children: [t()],
          id: id(),
          preset: nil | String.t(),
          type: Manifest.name(),
          version: Manifest.version()
        }

  @doc """
  Returns the node `serialized` describes, tolerantly.

  This is the path out of the database, and the only input the library reads
  that never passed through its own validation — a document is written by an
  editor and read back by whatever the row holds. So absence is filled rather
  than refused: a missing id is minted, a missing version assumes 1, missing
  attributes and children are empty, and a missing preset is `nil`. A malformed
  field value is treated exactly as absence — an `"attributes"` that is not a
  map, a `"children"` that is not a list, an `"id"` that is not a binary, a
  `"preset"` that is not a binary, a `"version"` that is not a positive integer
  — because a value this cannot use is one it can default, and the node is not
  the worse for it.

  Every field this reads is guarded, and the guards are the typespec written
  twice. A `jsonb` object can hold a map where a version belongs and a list
  where a preset belongs, and a field read without a guard puts that value
  straight into a struct whose `t()` says it cannot be there — which is a lie
  the compiler cannot catch and the next reader inherits. A version is counted
  with rather than merely stored, and a preset reaches the markup, where a map
  is not something that can be rendered. Neither is a shape a caller passes by
  mistake; both are shapes a database hands back.

  A field with an honest default is filled; a field without one is required.
  `type` has none — a node that does not name its block is not a node with a
  field missing — so a map without a string `"type"` raises
  `FunctionClauseError`. The `!` is that promise, and it reserves the bare name
  for an answering sibling, for the caller that cannot afford a raise.

  Tolerance also stops at the shape of what it is handed. A `"children"` list
  holding anything that is not itself a serialized node raises from inside the
  recursion, at the depth where it sits.

  ## Example

      iex> from_map!(%{"id" => "n_2Vwyyc_LKB7C", "type" => "test/example"})
      %Node{
        attributes: %{},
        children: [],
        id: "n_2Vwyyc_LKB7C",
        preset: nil,
        type: "test/example",
        version: 1
      }

  """
  @doc since: "0.3.0"
  @spec from_map!(serialized()) :: t()
  def from_map!(%{"type" => type} = serialized) when is_binary(type) do
    %__MODULE__{
      attributes: get_attributes(serialized),
      children: get_children(serialized),
      id: get_id(serialized),
      preset: get_preset(serialized),
      type: type,
      version: get_version(serialized)
    }
  end

  @doc """
  Returns a freshly minted node id.

  Nine bytes of entropy, url-safe and unpadded, behind an `n_` prefix. Nine
  bytes is 72 bits, which is collision-safe at page scale without an index;
  url-safe because an id reaches CSS selectors and data attributes; unpadded
  because `=` is neither.

  ## Example

      iex> generate_id() =~ ~r"^n_[A-Za-z0-9_-]{12}$"
      true

  """
  @doc since: "0.3.0"
  @spec generate_id() :: id()
  def generate_id() do
    9
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> then(&("n_" <> &1))
  end

  @doc """
  Returns `node` as a plain map, with string keys, recursively.

  This is the shape that persists. Keys are strings rather than atoms because
  the destination is `jsonb` and the return trip must not mint an atom from
  stored content — a document is written by an editor and read back by the same
  code, but the atom table is a global the content should not be able to grow.

  Every field is written, including a `nil` preset. A tolerant reader could
  absorb that key’s absence, so the pair could be asymmetric and the writer
  could omit it. It is written anyway: the stored shape is then one shape for
  every node, which is what lets a `jsonb` key set be relied on and a revision
  diff be read. Tolerance is the reader’s business; the writer states the
  whole node.

  ## Example

      iex> node = %Node{id: "n_CBNZeYIeMPAY", type: "test/example", version: 1}
      iex> to_map(node)
      %{
        "attributes" => %{},
        "children" => [],
        "id" => "n_CBNZeYIeMPAY",
        "preset" => nil,
        "type" => "test/example",
        "version" => 1
      }

  """
  @doc since: "0.3.0"
  @spec to_map(t()) :: serialized()
  def to_map(node) when is_struct(node, __MODULE__) do
    %{
      "attributes" => node.attributes,
      "children" => Enum.map(node.children, &to_map/1),
      "id" => node.id,
      "preset" => node.preset,
      "type" => node.type,
      "version" => node.version
    }
  end

  @spec get_attributes(serialized()) :: %{Manifest.key() => Attribute.value()}
  defp get_attributes(%{"attributes" => attributes}) when is_map(attributes) do
    attributes
  end

  defp get_attributes(_serialized), do: %{}

  @spec get_children(serialized()) :: [t()]
  defp get_children(serialized) do
    serialized
    |> take_children()
    |> Enum.map(&from_map!/1)
  end

  @spec get_id(serialized()) :: id()
  defp get_id(%{"id" => id}) when is_binary(id), do: id
  defp get_id(_serialized), do: generate_id()

  @spec get_preset(serialized()) :: nil | String.t()
  defp get_preset(%{"preset" => preset}) when is_binary(preset), do: preset
  defp get_preset(_serialized), do: nil

  @spec get_version(serialized()) :: Manifest.version()
  defp get_version(%{"version" => version})
       when is_integer(version) and version > 0 do
    version
  end

  defp get_version(_serialized), do: 1

  @spec take_children(serialized()) :: [term()]
  defp take_children(%{"children" => children}) when is_list(children) do
    children
  end

  defp take_children(_serialized), do: []
end
