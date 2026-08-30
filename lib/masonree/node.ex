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
end
