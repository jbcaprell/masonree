defmodule Masonree.Block.ParagraphTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Attribute

  @spec to_markup(Block.projection()) :: String.t()
  defp to_markup({rendered, _reports}) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  describe "manifest/0" do
    import Block.Paragraph, only: [manifest: 0]

    test "returns the declaration whole" do
      assert manifest() == %Manifest{
               attributes: %{
                 "content" => %Attribute{
                   default: "",
                   role: :content,
                   type: :string
                 }
               },
               category: "text",
               label: "Paragraph",
               name: "core/paragraph",
               version: 1
             }
    end
  end

  describe "render/1" do
    import Block.Paragraph, only: [render: 1]

    test "escapes the text, which is not the author’s to decide" do
      assigns = %{
        __changed__: nil,
        html_attributes: [],
        node: %Node{
          attributes: %{"content" => "<strong>Hello, world!</strong>"},
          id: "n_q0-LXg_nhJMj",
          type: "core/paragraph",
          version: 1
        }
      }

      projection = render(assigns)

      assert to_markup(projection) ==
               "<p>&lt;strong&gt;Hello, world!&lt;/strong&gt;</p>"
    end

    test "reports nothing about content it can render" do
      assigns = %{
        __changed__: nil,
        html_attributes: [],
        node: %Node{
          attributes: %{"content" => ""},
          id: "n__NOSldwaAadp",
          type: "core/paragraph",
          version: 1
        }
      }

      projection = render(assigns)

      assert {_rendered, []} = projection
      assert to_markup(projection) == "<p></p>"
    end

    test "splices the attributes it is handed into the root" do
      assigns = %{
        __changed__: nil,
        html_attributes: [{"class", "example"}],
        node: %Node{
          attributes: %{"content" => "Hello, world!"},
          id: "n_kxSnnj9pgUn5",
          type: "core/paragraph",
          version: 1
        }
      }

      projection = render(assigns)

      assert to_markup(projection) == ~S(<p class="example">Hello, world!</p>)
    end
  end
end
