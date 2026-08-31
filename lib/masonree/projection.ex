defmodule Masonree.Projection do
  @moduledoc """
  Defines the markup a document becomes.

  A block answers for one node. `Masonree.Block` fixes what a block declares and
  what it renders, and neither callback is handed a second node — walking a
  document and composing what comes back is a different job, and it lives here
  rather than on the behaviour every block implements. A block that could reach
  its siblings would be a block no developer could write alone.

  A node that cannot become markup is reported, never raised. A page is mostly
  other people’s content, and one unknown type or one block that declares no
  markup should cost the reader that node and not the page — so every path out
  of the walk carries markup and problems together, and the caller decides what
  a problem is worth.

  ## Example

      iex> document = %Document{
      ...>   root: [
      ...>     %Node{
      ...>       attributes: %{"content" => "Hello, world!"},
      ...>       id: "n_Cl3RxFieqfwo",
      ...>       type: "core/paragraph",
      ...>       version: 1
      ...>     }
      ...>   ]
      ...> }
      iex>
      iex> blocks = %{"core/paragraph" => Block.Paragraph}
      iex> {rendered, []} = render(document, blocks, :public)
      iex>
      iex> bytes = Enum.map(rendered, &Phoenix.HTML.Safe.to_iodata/1)
      iex> IO.iodata_to_binary(bytes)
      "<p>Hello, world!</p>"

  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Block
  alias Masonree.Document
  alias Masonree.Manifest
  alias Masonree.Node

  @typedoc "Represents the module a node’s block is declared in."
  @typedoc since: "0.3.0"
  @type block() :: module()

  @typedoc "Represents block names resolved to the modules declaring them."
  @typedoc since: "0.3.0"
  @type blocks() :: %{Manifest.name() => block()}

  @typedoc "Represents the document under projection."
  @typedoc since: "0.3.0"
  @type document() :: Document.t()

  @typedoc "Represents whether the markup is for a visitor or an editor."
  @typedoc since: "0.3.0"
  @type mode() :: :editor | :public

  @typedoc "Represents one node that became no markup, or one thing said."
  @typedoc since: "0.3.0"
  @type problem() ::
          {:reported, Node.id(), Block.report()}
          | {:unknown_block, Node.id()}
          | {:unrenderable_block, Node.id()}

  @typedoc "Represents everything the walk found, in document order."
  @typedoc since: "0.3.0"
  @type problems() :: [problem()]

  @typedoc "Represents the markup, and everything the walk found making it."
  @typedoc since: "0.3.0"
  @type projection() :: {rendered(), problems()}

  @typedoc "Represents the markup a document became."
  @typedoc since: "0.3.0"
  @type rendered() :: [Block.rendered()]

  @doc """
  Returns the markup `document` becomes, and everything found on the way.

  The walk. Children render before their parent and reach it as a slot, so a
  container composes an interior it never had to go looking for; siblings render
  in document order and their problems accumulate in that order too.

  A block’s own findings ride as `{:reported, id, term}` — the library fixes no
  taxonomy for them, because a taxonomy with no members is an invitation to
  invent one.

  `mode` says who the markup is for. It is a parameter rather than two functions
  because it has to reach every node of a nested walk, and a caller that chose
  per node could render a page half of which an editor cannot select. Its one
  effect is what reaches `@html_attributes`, and nothing is contributed there
  yet — the assign is the contract, and its suppliers land next.
  """
  @doc since: "0.3.0"
  @spec render(document(), blocks(), mode()) :: projection()
  def render(document, blocks, mode)
      when is_struct(document, Document) and is_map(blocks) do
    render_list(document.root, blocks, mode)
  end

  @doc """
  Returns whether `block` can project a node into markup.

  A block that never renders is legal and useful — `Masonree.Block` makes
  `c:Masonree.Block.render/1` optional and `c:Masonree.Block.manifest/0`
  mandatory — so this is a question with a real `false`. `render/3` asks it
  before projecting, and reports `{:unrenderable_block, id}` where the answer is
  `false` rather than raising `UndefinedFunctionError` on a module that chose
  the legal smaller shape.

  ## Example

      iex> renderable?(Block.Paragraph)
      true

  """
  @doc since: "0.3.0"
  @spec renderable?(block()) :: boolean()
  def renderable?(block) do
    Code.ensure_loaded?(block) and function_exported?(block, :render, 1)
  end

  @spec fill(Node.t(), rendered(), mode()) :: Block.assigns()
  defp fill(node, interior, _mode) do
    %{
      __changed__: nil,
      html_attributes: [],
      inner_block: take_slot(interior),
      node: node
    }
  end

  @spec project(Node.t(), module(), blocks(), mode()) :: projection()
  defp project(node, module, blocks, mode) do
    {interior, nested} = take_interior(node, blocks, mode)
    assigns = fill(node, interior, mode)
    {rendered, reports} = module.render(assigns)

    named = Enum.map(reports, &{:reported, node.id, &1})

    {[rendered], named ++ nested}
  end

  @spec render_list([Node.t()], blocks(), mode()) :: projection()
  defp render_list(nodes, blocks, mode) do
    {rendered, problems} =
      Enum.map_reduce(nodes, [], fn node, acc ->
        {markup, found} = render_node(node, blocks, mode)

        {markup, acc ++ found}
      end)

    {Enum.concat(rendered), problems}
  end

  @spec render_node(Node.t(), blocks(), mode()) :: projection()
  defp render_node(node, blocks, mode) do
    case Map.get(blocks, node.type) do
      nil -> {[], [{:unknown_block, node.id}]}
      module -> take_markup(node, module, blocks, mode)
    end
  end

  @spec take_interior(Node.t(), blocks(), mode()) :: projection()
  defp take_interior(node, blocks, mode) do
    render_list(node.children, blocks, mode)
  end

  @spec take_markup(Node.t(), module(), blocks(), mode()) :: projection()
  defp take_markup(node, module, blocks, mode) do
    if renderable?(module) do
      project(node, module, blocks, mode)
    else
      {[], [{:unrenderable_block, node.id}]}
    end
  end

  @spec take_slot(rendered()) :: [map()]
  defp take_slot(interior) do
    inner_block =
      fn _argument, _assigns ->
        {:safe, Enum.map(interior, &Phoenix.HTML.Safe.to_iodata/1)}
      end

    [%{__slot__: :inner_block, inner_block: inner_block}]
  end
end
