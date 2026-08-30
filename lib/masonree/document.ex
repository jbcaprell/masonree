defmodule Masonree.Document do
  @moduledoc """
  Defines a page as an ordered list of nodes.

  A document is a tree of `Masonree.Node` structs and nothing else. It holds no
  identity of its own — the row that stores it has one — and no envelope
  version, because the migration index is stamped into every node and a second
  one on the envelope would have no mechanism behind it. If the envelope shape
  ever does change, the reader can tolerate the older shape the way
  `Masonree.Node.from_map!/1` tolerates a missing version, so nothing is
  foreclosed by leaving it out and a field is not carried until something
  consumes it.

  What may sit at the root is the container’s decision, not the document’s. The
  struct admits any node in any order; a document that policed its own root
  would be the second place that rule lived.

  An empty document is legal, and is what a page is before anything is inserted
  into it.

  ## Examples

      iex> node = %Node{id: "n_SH_neVyCLem9", type: "test/example", version: 1}
      iex> %Document{root: [node]}
      %Document{
        root: [
          %Node{
            attributes: %{},
            children: [],
            id: "n_SH_neVyCLem9",
            preset: nil,
            type: "test/example",
            version: 1
          }
        ]
      }

      iex> %Document{}
      %Document{root: []}

  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Node

  defstruct root: []

  @typedoc "Represents the document."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{root: [Node.t()]}
end
