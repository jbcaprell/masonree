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
  block, as each class of malformed declaration is one function over a manifest
  in `Masonree.Manifest`.

  Whether a type may hold a value is not answered here: the member answers,
  through `Masonree.Type.admits?/2`, and this module never learns what a type
  is. Problems carry the node’s id and whatever the document cannot already
  supply — the id finds the node, the node knows its type, so an unknown block
  needs no second element where an attribute problem names its key.
  """
  @moduledoc since: "0.7.0"

  alias Masonree

  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Attribute

  @typedoc "Represents the node a finding is about."
  @typedoc since: "0.7.0"
  @type block_node() :: Node.t()

  @typedoc "Represents the declaration a node is judged against."
  @typedoc since: "0.7.0"
  @type manifest() :: Manifest.t()

  @typedoc "Represents one finding about one node."
  @typedoc since: "0.7.0"
  @type problem() ::
          {:missing_attribute, Node.id(), Manifest.key()}
          | {:unknown_attribute, Node.id(), Manifest.key()}

  @typedoc "Represents every finding reported."
  @typedoc since: "0.7.0"
  @type problems() :: [problem()]

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
end
