defmodule Masonree.Manifest.Template do
  @moduledoc """
  Defines the tree a block’s interior starts from.

  A template is a recipe, not content. Each entry names a block type, the
  attribute values the stamped node starts with, and the entries beneath it —
  and deliberately nothing else. Identity, version and preset belong to nodes,
  and exist only once a template is stamped; a template holding those fields
  would invite code to treat an unstamped shape as a page, and a template
  holding `Masonree.Node` structs would make the manifest depend on the model
  layer beneath it.

  An empty interior needs no template at all: a block whose containment declares
  none starts empty, so `%Template{}` has no meaning of its own and the `type`
  key is enforced.

  `label` is what an inserter shows, and it is enforced for the same reason
  `type` is. A containment offers its templates as a list, so a template is
  always one of several possible answers to what a block starts as — and an
  unlabeled entry in that list is one the author cannot name and an editor
  cannot draw. It is display and nothing else: nothing stamps it, no node
  records which template it came from, and changing it changes no content.

  ## Examples

      iex> %Template{label: "Template", type: "test/example"}
      %Template{
        attributes: %{},
        children: [],
        label: "Template",
        type: "test/example"
      }

      iex> template = %Template{
      ...>   children: [%Template{label: "Child", type: "test/example"}],
      ...>   label: "Template",
      ...>   type: "test/example"
      ...> }
      iex>
      iex> [child] = template.children
      iex> child.label
      "Child"

  """
  @moduledoc since: "0.6.0"

  alias Masonree

  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Attribute

  @enforce_keys [:label, :type]
  defstruct attributes: %{}, children: [], label: nil, type: nil

  @typedoc "Represents one stamped node."
  @typedoc since: "0.6.0"
  @type block_node() :: Node.t()

  @typedoc "Represents the manifests stamping consults, by block name."
  @typedoc since: "0.6.0"
  @type manifests() :: %{type() => Manifest.t()}

  @typedoc "Represents the template."
  @typedoc since: "0.6.0"
  @type t() :: %__MODULE__{
          attributes: %{Manifest.key() => Attribute.value()},
          children: [t()],
          label: String.t(),
          type: type()
        }

  @typedoc "Represents the block type an entry stamps."
  @typedoc since: "0.6.0"
  @type type() :: Manifest.name()

  @doc """
  Returns a fresh node stamped from `template`.

  Every entry passes through `Masonree.Node.new/3` against its own manifest, so
  declared defaults are applied, the version is the manifest’s, and every id is
  minted new at every stamping — a template stamped twice yields two trees
  sharing nothing but their shape.

  An entry whose type `manifests` does not name raises `KeyError`. That is the
  one place this module refuses rather than reports: a template naming an absent
  block is authored junk in a compiled module, not stored content to tolerate,
  and the tolerant posture the read boundary keeps is about pages that outlived
  their blocks.

  ## Example

      iex> manifests = %{
      ...>   "test/example" => %Manifest{name: "test/example", version: 1}
      ...> }
      iex>
      iex> template = %Template{
      ...>   children: [%Template{label: "Child", type: "test/example"}],
      ...>   label: "Template",
      ...>   type: "test/example"
      ...> }
      iex>
      iex> node = stamp(template, manifests)
      iex> {node.type, node.version, length(node.children)}
      {"test/example", 1, 1}

  """
  @doc since: "0.6.0"
  @spec stamp(t(), manifests()) :: block_node()
  def stamp(template, manifests)
      when is_struct(template, __MODULE__) and is_map(manifests) do
    manifest = Map.fetch!(manifests, template.type)
    children = Enum.map(template.children, &stamp(&1, manifests))

    Node.new(manifest, template.attributes, children)
  end
end
