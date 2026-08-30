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

  @typedoc "Represents the document as a plain map, the shape that persists."
  @typedoc since: "0.3.0"
  @type serialized() :: %{String.t() => term()}

  @typedoc "Represents the document."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{root: [Node.t()]}

  @doc """
  Reads a document from `serialized`, tolerating every absence with a default.

  This is the path out of the database, and the shape it reads never passed
  through this library’s validation. So absence is filled rather than refused: a
  missing `"root"` becomes `[]`, and so does a `"root"` that is not a list. An
  empty document is legal, because a page is empty before anything is inserted
  into it.

  Tolerance stops at `Masonree.Node.from_map!/1`, and is not repeated here. A
  `"root"` entry that is not a serialized node raises `FunctionClauseError` from
  inside the node’s reader rather than from this call. The document is tolerant
  about its own field and delegates the rest, so there is one boundary with one
  posture instead of two that can drift. The `!` is that promise, and it
  reserves the bare name for an answering sibling, for the caller that cannot
  afford a raise.

  Tolerance also stops short of a struct, which raises here rather than being
  read as an envelope with everything absent. A struct is a map, so a guard that
  asked only that much would read a `%Masonree.Node{}` as an envelope with no
  `"root"` key and answer with an empty document — a whole page turned into
  nothing, silently, by the one shape a caller is most likely to pass here by
  mistake. An envelope is a decoded jsonb object and is never a struct, so the
  guard says so.

  ## Examples

      iex> document = %{
      ...>   "root" => [%{"id" => "n_KuCOuIHzdILO", "type" => "test/example"}]
      ...> }
      iex>
      iex> from_map!(document)
      %Document{
        root: [
          %Node{
            attributes: %{},
            children: [],
            id: "n_KuCOuIHzdILO",
            preset: nil,
            type: "test/example",
            version: 1
          }
        ]
      }

      iex> from_map!(%{})
      %Document{root: []}

  """
  @doc since: "0.3.0"
  @spec from_map!(serialized()) :: t()
  def from_map!(serialized)
      when is_map(serialized) and not is_struct(serialized) do
    %__MODULE__{root: get_root(serialized)}
  end

  @doc """
  Returns `document` as a plain map, with string keys.

  The envelope is written as an object, not as a bare list, even though it holds
  one key today. A stored list cannot grow a second field without rewriting
  every row; a stored object can, and the reader can tolerate the older shape
  while it does. That is what makes leaving out an envelope version safe rather
  than merely cheap: the room one would need is here, unoccupied and free.

  The nodes beneath are written by `Masonree.Node.to_map/1`, which states every
  field including the nils, so a document has one stored shape for every node
  in it.

  ## Example

      iex> document = %Document{
      ...>   root: [
      ...>     %Node{id: "n_2nuJgad8e455", type: "test/example", version: 1}
      ...>   ]
      ...> }
      iex>
      iex> to_map(document)
      %{
        "root" => [
          %{
            "attributes" => %{},
            "children" => [],
            "id" => "n_2nuJgad8e455",
            "preset" => nil,
            "type" => "test/example",
            "version" => 1
          }
        ]
      }

  """
  @doc since: "0.3.0"
  @spec to_map(t()) :: serialized()
  def to_map(document) when is_struct(document, __MODULE__) do
    %{"root" => Enum.map(document.root, &Node.to_map/1)}
  end

  @spec get_root(serialized()) :: [Node.t()]
  defp get_root(serialized) do
    serialized
    |> take_root()
    |> Enum.map(&Node.from_map!/1)
  end

  @spec take_root(serialized()) :: [term()]
  defp take_root(%{"root" => root}) when is_list(root), do: root
  defp take_root(_serialized), do: []
end
