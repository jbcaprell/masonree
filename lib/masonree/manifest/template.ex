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

  alias Manifest.Attribute

  @enforce_keys [:label, :type]
  defstruct attributes: %{}, children: [], label: nil, type: nil

  @typedoc "Represents the template."
  @typedoc since: "0.6.0"
  @type t() :: %__MODULE__{
          attributes: %{Manifest.key() => Attribute.value()},
          children: [t()],
          label: String.t(),
          type: Manifest.name()
        }
end
