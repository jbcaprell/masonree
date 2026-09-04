defmodule Masonree.Conformance do
  @moduledoc """
  Defines conformance reporting over a document.

  This module reports and never raises on content. A stored page outlives the
  blocks that made it — a deactivated block leaves its nodes behind — and a page
  that could not be loaded because one block is gone would make every
  deactivation a data loss. So an unknown block is a report, a malformed
  attribute value is a report, and the page survives every one of them. Raising
  is the read boundary’s posture about malformed envelopes, and it stops there.

  A report changes nothing. Repairing what a report finds is another module’s
  work, and one function that both judged and healed would carry two postures
  with no way to ask for either alone. When to check is the caller’s: on drop,
  on save, on publish — this module only answers.

  The manifests are consulted as a plain map from block name to manifest, a
  shape any caller can build from whatever holds its blocks. Each class of
  problem is one function over a node and the manifest that declares its
  block, as each class of malformed declaration is one function over a
  manifest in `Masonree.Manifest`, and `validate/2` gathers every class over
  every node of a document as `Masonree.Manifest.validate/1` gathers every class
  over a manifest.

  Whether a type may hold a value is not answered here: the member answers,
  through `Masonree.Type.admits?/2`, and this module never learns what a type
  is. Problems carry the node’s id and whatever the document cannot already
  supply — the id finds the node, the node knows its type, so an unknown block
  needs no second element where an attribute problem names its key.

  ## Example

      iex> document = %Document{
      ...>   root: [
      ...>     %Node{id: "n_x2JpBOqiitAS", type: "test/example", version: 1}
      ...>   ]
      ...> }
      iex>
      iex> manifests = %{
      ...>   "test/example" => %Manifest{name: "test/example", version: 1}
      ...> }
      iex>
      iex> validate(document, manifests)
      []

  """
  @moduledoc since: "0.7.0"

  alias Masonree

  alias Masonree.Document
  alias Masonree.Manifest
  alias Masonree.Node
  alias Masonree.Type

  alias Manifest.Attribute
  alias Manifest.Containment

  @typedoc "Represents the node a finding is about."
  @typedoc since: "0.7.0"
  @type block_node() :: Node.t()

  @typedoc "Represents the rule a node’s interior is judged against."
  @typedoc since: "0.7.0"
  @type containment() :: Containment.t()

  @typedoc "Represents the document under report."
  @typedoc since: "0.7.0"
  @type document() :: Document.t()

  @typedoc "Represents the declaration a node is judged against."
  @typedoc since: "0.7.0"
  @type manifest() :: Manifest.t()

  @typedoc "Represents the manifests consulted, by block name."
  @typedoc since: "0.7.0"
  @type manifests() :: %{Manifest.name() => manifest()}

  @typedoc "Represents one finding about one node."
  @typedoc since: "0.7.0"
  @type problem() ::
          {:bad_attribute_value, Node.id(), Manifest.key()}
          | {:missing_attribute, Node.id(), Manifest.key()}
          | {:refused_child, Node.id(), Node.id()}
          | {:too_few_children, Node.id()}
          | {:too_many_children, Node.id()}
          | {:unknown_attribute, Node.id(), Manifest.key()}
          | {:unknown_block, Node.id()}

  @typedoc "Represents every finding reported."
  @typedoc since: "0.7.0"
  @type problems() :: [problem()]

  @doc """
  Returns every problem in `document`, in document order, against `manifests`.

  Each node answers whole. An unknown block ends the node’s report: attributes
  cannot be judged against a manifest that is not there, so the one finding
  stands alone rather than heading a cascade. A known block reports every class
  — keys, requiredness, values, admission, cardinality — concatenated and
  sorted, as `Masonree.Manifest.validate/1` sorts a manifest’s, so that a node’s
  report is deterministic whatever the map order underneath. Sorted is term
  order: a count finding, being the shorter tuple, leads a node’s report, and
  refused children stand by child id. Nodes answer in document order — the
  walk’s order — so the page’s report keeps the page’s order with each node’s
  findings sorted within it, and two runs over one page agree to the finding. An
  empty report is the document conforming; an empty document conforms vacuously,
  there being nothing to report on.

  The same tuple `Masonree.Projection` reports for a block it cannot render,
  `{:unknown_block, id}`, names the same fact here: one vocabulary, wherever the
  fact surfaces.

  What sits at the top of the page is not judged here: that is the container’s
  question, asked with the container’s own rule in hand, and a document knows
  no container.

  ## Example

      iex> document = %Document{
      ...>   root: [%Node{id: "n_uV2ZAiyerpTg", type: "test/rogue", version: 1}]
      ...> }
      iex>
      iex> validate(document, %{})
      [{:unknown_block, "n_uV2ZAiyerpTg"}]

  """
  @doc since: "0.7.0"
  @spec validate(document(), manifests()) :: problems()
  def validate(document, manifests)
      when is_struct(document, Document) and is_map(manifests) do
    nodes = Document.walk(document)

    Enum.flat_map(nodes, &validate_node(&1, manifests))
  end

  @doc """
  Returns a rejection for each child of `node` that `manifest` refuses.

  A child the containment refuses reports from the parent’s position —
  `{:refused_child, parent, child}` — because the refusal is the parent’s
  finding about its own interior, and the pair of ids is what an editor needs to
  show both ends of it. Whether a name is admitted is the rule’s question,
  `Masonree.Manifest.Containment.admits?/2`, and this module adds nothing to the
  answer. A manifest declaring no containment admits any interior: `nil` is the
  absence of the rule, and absence refuses nothing. Children report in the order
  the node holds them.

  ## Example

      iex> node = %Node{
      ...>   children: [
      ...>     %Node{id: "n_UysjCPMEG4GB", type: "test/rogue", version: 1}
      ...>   ],
      ...>   id: "n_2NDkyfled3-Q",
      ...>   type: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> manifest = %Manifest{
      ...>   containment: %Containment{allowed: ["test/example"]},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_admission(node, manifest)
      [{:refused_child, "n_2NDkyfled3-Q", "n_UysjCPMEG4GB"}]

  """
  @doc since: "0.7.0"
  @spec validate_admission(block_node(), manifest()) :: problems()
  def validate_admission(node, %Manifest{containment: nil})
      when is_struct(node, Node) do
    []
  end

  def validate_admission(node, %Manifest{containment: containment})
      when is_struct(node, Node) do
    for child <- node.children,
        not Containment.admits?(containment, child.type) do
      {:refused_child, node.id, child.id}
    end
  end

  @doc """
  Returns the rejection where `node`’s children breach `manifest`’s bounds.

  One finding per interior, however many children breach: a count below the
  floor reports `{:too_few_children, id}` and one above the ceiling reports
  `{:too_many_children, id}`, once, because the repair is one edit to one
  interior and a finding per excess child would be the same fact counted. A
  ceiling of `nil` is no ceiling, and a manifest declaring no containment admits
  any count. The two bounds cannot both be breached —
  `Masonree.Manifest.validate_cardinality/1` refused that declaration at the
  block’s own compile.

  ## Example

      iex> node = %Node{id: "n_Sf3Ptv7SBQ-A", type: "test/example", version: 1}
      iex>
      iex> manifest = %Manifest{
      ...>   containment: %Containment{minimum: 1},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_cardinality(node, manifest)
      [{:too_few_children, "n_Sf3Ptv7SBQ-A"}]

  """
  @doc since: "0.7.0"
  @spec validate_cardinality(block_node(), manifest()) :: problems()
  def validate_cardinality(node, %Manifest{containment: nil})
      when is_struct(node, Node) do
    []
  end

  def validate_cardinality(node, %Manifest{containment: containment})
      when is_struct(node, Node) do
    count = length(node.children)

    cond do
      count < containment.minimum -> [{:too_few_children, node.id}]
      overfull?(count, containment.maximum) -> [{:too_many_children, node.id}]
      true -> []
    end
  end

  @doc """
  Returns a rejection for each key `node` holds that `manifest` never declared.

  A stored key with no declaration is content the manifest cannot explain — an
  attribute renamed since the page was saved, or written by a block since
  changed — and every such key is named in its own rejection. What to do about
  one is not answered here: a report changes nothing. The keys report in the
  order the node’s attribute map iterates, which above 32 keys is not the order
  they were written in.

  ## Example

      iex> node = %Node{
      ...>   attributes: %{"content" => "Hello, world!", "level" => 2},
      ...>   id: "n_9Nh3XZbvenaz",
      ...>   type: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> manifest = %Manifest{
      ...>   attributes: %{"content" => %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_keys(node, manifest)
      [{:unknown_attribute, "n_9Nh3XZbvenaz", "level"}]

  """
  @doc since: "0.7.0"
  @spec validate_keys(block_node(), manifest()) :: problems()
  def validate_keys(node, %Manifest{attributes: attributes})
      when is_struct(node, Node) do
    for {key, _value} <- node.attributes,
        not Map.has_key?(attributes, key) do
      {:unknown_attribute, node.id, key}
    end
  end

  @doc """
  Returns a rejection for each required key `node` holds nothing at.

  Requiredness means no honest default exists, so the one thing it can refuse is
  absence — the key missing from the node altogether. A key held with any value,
  `nil` included, is held: what the value may be is the type’s question, asked
  elsewhere, and the two questions never report the same key for the same
  reason. The keys report in the order the manifest’s attribute map iterates.

  ## Example

      iex> node = %Node{id: "n_MHSy2NEcxAOr", type: "test/example", version: 1}
      iex>
      iex> manifest = %Manifest{
      ...>   attributes: %{
      ...>     "src" => %Attribute{
      ...>       required: true,
      ...>       role: :content,
      ...>       type: :string
      ...>     }
      ...>   },
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_requiredness(node, manifest)
      [{:missing_attribute, "n_MHSy2NEcxAOr", "src"}]

  """
  @doc since: "0.7.0"
  @spec validate_requiredness(block_node(), manifest()) :: problems()
  def validate_requiredness(node, %Manifest{attributes: attributes})
      when is_struct(node, Node) do
    for {key, %Attribute{required: true}} <- attributes,
        not Map.has_key?(node.attributes, key) do
      {:missing_attribute, node.id, key}
    end
  end

  @doc """
  Returns a rejection for each value `node` holds that its type refuses.

  The question is the member’s — `Masonree.Type.admits?/2`, asked with the
  declared type — and this module adds nothing to the answer. Only a held key
  with a declaration is asked: an undeclared key has no type to ask, and an
  absent one holds nothing to judge, each being another function’s finding. A
  `nil` is admitted by every member of the lattice, so a held `nil` is never a
  wrong value here: absence is requiredness’s question, asked elsewhere, and the
  two questions never report the same key for the same reason. The keys report
  in the order the manifest’s attribute map iterates.

  ## Example

      iex> node = %Node{
      ...>   attributes: %{"rank" => "2"},
      ...>   id: "n_hkNIVsdOM2A4",
      ...>   type: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> manifest = %Manifest{
      ...>   attributes: %{"rank" => %Attribute{role: :chrome, type: :number}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_values(node, manifest)
      [{:bad_attribute_value, "n_hkNIVsdOM2A4", "rank"}]

  """
  @doc since: "0.7.0"
  @spec validate_values(block_node(), manifest()) :: problems()
  def validate_values(node, %Manifest{attributes: attributes})
      when is_struct(node, Node) do
    for {key, %Attribute{type: type}} <- attributes,
        Map.has_key?(node.attributes, key),
        not Type.admits?(type, Map.fetch!(node.attributes, key)) do
      {:bad_attribute_value, node.id, key}
    end
  end

  @spec overfull?(non_neg_integer(), nil | non_neg_integer()) :: boolean()
  defp overfull?(_count, nil), do: false
  defp overfull?(count, maximum), do: count > maximum

  @spec validate_node(block_node(), manifests()) :: problems()
  defp validate_node(node, manifests) do
    case Map.fetch(manifests, node.type) do
      :error ->
        [{:unknown_block, node.id}]

      {:ok, manifest} ->
        reports = [
          validate_admission(node, manifest),
          validate_cardinality(node, manifest),
          validate_keys(node, manifest),
          validate_requiredness(node, manifest),
          validate_values(node, manifest)
        ]

        reports
        |> Enum.concat()
        |> Enum.sort()
    end
  end
end
