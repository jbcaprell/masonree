defmodule Masonree.Projection do
  @moduledoc """
  Defines the markup a document becomes.

  A block answers for one node. `Masonree.Block` fixes what a block declares and
  what it renders, and neither callback is handed a second node — walking a
  document and composing what comes back is a different job, and it lives here
  rather than on the behaviour every block implements. A block that could reach
  its siblings would be a block no developer could write alone.
  """
  @moduledoc since: "0.3.0"

  @typedoc "Represents the module a node’s block is declared in."
  @typedoc since: "0.3.0"
  @type block() :: module()

  @doc """
  Returns whether `block` can project a node into markup.

  A block that never renders is legal and useful — `Masonree.Block` makes
  `c:Masonree.Block.render/1` optional and `c:Masonree.Block.manifest/0`
  mandatory — so this is a question with a real `false`, and a caller that
  assumed otherwise would raise `UndefinedFunctionError` on a module that
  chose the legal smaller shape.

  ## Example

      iex> renderable?(Block.Paragraph)
      true

  """
  @doc since: "0.3.0"
  @spec renderable?(block()) :: boolean()
  def renderable?(block) do
    Code.ensure_loaded?(block) and function_exported?(block, :render, 1)
  end
end
