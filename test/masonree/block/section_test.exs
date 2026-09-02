defmodule Masonree.Block.SectionTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.6.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Containment
  alias Manifest.Template

  @spec to_markup(Block.projection()) :: String.t()
  defp to_markup({rendered, _reports}) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  @spec to_slot(String.t()) :: [map()]
  defp to_slot(markup) do
    [
      %{
        __slot__: :inner_block,
        inner_block: fn _argument, _assigns -> {:safe, markup} end
      }
    ]
  end

  describe "manifest/0" do
    import Block.Section, only: [manifest: 0]

    test "returns the declaration whole" do
      assert manifest() == %Manifest{
               category: "layout",
               containment: %Containment{
                 templates: [
                   %Template{label: "Paragraph", type: "core/paragraph"}
                 ]
               },
               label: "Section",
               name: "core/section",
               version: 1
             }
    end
  end

  describe "render/1" do
    import Block.Section, only: [render: 1]

    test "renders the interior in its slot" do
      assigns = %{
        __changed__: nil,
        html_attributes: [],
        inner_block: to_slot("<p>Hello, world!</p>"),
        node: %Node{
          attributes: %{},
          id: "n_HZ9lYCV3EWjo",
          type: "core/section",
          version: 1
        }
      }

      projection = render(assigns)

      assert to_markup(projection) == "<section><p>Hello, world!</p></section>"
    end

    test "reports nothing about content it can render" do
      assigns = %{
        __changed__: nil,
        html_attributes: [],
        inner_block: to_slot(""),
        node: %Node{
          attributes: %{},
          id: "n_5oz8oTgFH1nQ",
          type: "core/section",
          version: 1
        }
      }

      projection = render(assigns)

      assert {_rendered, []} = projection
      assert to_markup(projection) == "<section></section>"
    end

    test "splices the attributes it is handed into the root" do
      assigns = %{
        __changed__: nil,
        html_attributes: [{"class", "example"}],
        inner_block: to_slot(""),
        node: %Node{
          attributes: %{},
          id: "n_x0BJb-24AjRw",
          type: "core/section",
          version: 1
        }
      }

      projection = render(assigns)

      assert to_markup(projection) == ~S(<section class="example"></section>)
    end
  end
end
