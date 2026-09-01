defmodule Masonree.Block.Paragraph do
  @moduledoc """
  Defines a block.

  A paragraph: one run of text. `content` holds it, and holds all of it — a
  paragraph declares nothing else.

  The default is the empty string rather than `required: true`, because
  requiredness means no honest default exists and for a run of text one does. A
  paragraph is inserted before it is written, and the empty string is the value
  it holds in between.
  """
  @moduledoc since: "0.3.0"

  use Masonree.Block

  @manifest %Manifest{
    attributes: %{
      "content" => %Attribute{default: "", role: :content, type: :string}
    },
    category: "text",
    label: "Paragraph",
    name: "core/paragraph",
    version: 1
  }

  @impl Masonree.Block
  def render(assigns) do
    assigns = assign(assigns, :content, assigns.node.attributes["content"])

    rendered =
      ~H"""
      <p {@html_attributes}>{@content}</p>
      """

    {rendered, []}
  end
end
