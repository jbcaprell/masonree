defmodule Masonree.ProjectionTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Document
  alias Masonree.Node
  alias Masonree.Projection

  doctest Projection, import: true

  @blocks %{
    "core/paragraph" => Block.Paragraph,
    "test/reporting" => __MODULE__.Reporting,
    "test/silent" => __MODULE__.Silent,
    "test/wrapping" => __MODULE__.Wrapping
  }

  @spec build_paragraph(Node.id(), String.t()) :: Node.t()
  defp build_paragraph(id, content) do
    %Node{
      attributes: %{"content" => content},
      id: id,
      type: "core/paragraph",
      version: 1
    }
  end

  @spec to_markup(Projection.rendered()) :: String.t()
  defp to_markup(rendered) do
    rendered
    |> Projection.to_iodata()
    |> IO.iodata_to_binary()
  end

  describe "render/3" do
    import Projection, only: [render: 3]

    test "accumulates problems in document order" do
      document = %Document{
        root: [
          %Node{id: "n_tBhgl2qwXA7K", type: "test/gone", version: 1},
          build_paragraph("n_02euloUAe9DY", "Hello, world!"),
          %Node{id: "n_58CfR-5sI0EM", type: "test/silent", version: 1}
        ]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) == "<p>Hello, world!</p>"

      assert problems == [
               {:unknown_block, "n_tBhgl2qwXA7K"},
               {:unrenderable_block, "n_58CfR-5sI0EM"}
             ]
    end

    test "carries a block’s own findings, stamped with its id" do
      document = %Document{
        root: [%Node{id: "n_IJh1GqtyfU8b", type: "test/reporting", version: 1}]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) == "<aside>Reported!</aside>"
      assert problems == [{:reported, "n_IJh1GqtyfU8b", :looked_fine}]
    end

    test "composes a container’s interior, children first" do
      document = %Document{
        root: [
          %Node{
            children: [build_paragraph("n_NX3_-SiYDOeK", "Hello, world!")],
            id: "n_QLTDKXtw6oDA",
            type: "test/wrapping",
            version: 1
          }
        ]
      }

      {rendered, []} = render(document, @blocks, :public)

      assert to_markup(rendered) == "<div><p>Hello, world!</p></div>"
    end

    test "descends, so a child’s problem surfaces" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!"},
            children: [
              %Node{id: "n_tBhgl2qwXA7K", type: "test/gone", version: 1}
            ],
            id: "n_ZazV3ZSV4fVV",
            type: "core/paragraph",
            version: 1
          }
        ]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) == "<p>Hello, world!</p>"
      assert problems == [{:unknown_block, "n_tBhgl2qwXA7K"}]
    end

    test "drops an unknown block and its interior, and reports it" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{id: "n_sf0DfX2iHH1C", type: "test/silent", version: 1}
            ],
            id: "n_JE2xuXRLOmyU",
            type: "test/gone",
            version: 1
          }
        ]
      }

      assert render(document, @blocks, :public) ==
               {[], [{:unknown_block, "n_JE2xuXRLOmyU"}]}
    end

    test "keeps the page around a node it cannot place" do
      document = %Document{
        root: [
          build_paragraph("n_02euloUAe9DY", "Hello, world!"),
          %Node{id: "n_tBhgl2qwXA7K", type: "test/gone", version: 1},
          build_paragraph("n_Z-zPpp7Cn7Es", "Goodbye, world!")
        ]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) == "<p>Hello, world!</p><p>Goodbye, world!</p>"
      assert problems == [{:unknown_block, "n_tBhgl2qwXA7K"}]
    end

    test "raises when blocks is not a map" do
      blocks = JSON.decode!("[]")

      assert_raise FunctionClauseError, fn ->
        render(%Document{}, blocks, :public)
      end
    end

    test "renders nothing and reports nothing for an empty document" do
      assert render(%Document{}, @blocks, :public) == {[], []}
    end
  end

  describe "renderable?/1" do
    import Projection, only: [renderable?: 1]

    test "answers false for a manifest-only block, which is legal" do
      refute renderable?(__MODULE__.Silent)
    end

    test "answers true for a block with markup" do
      assert renderable?(Block.Paragraph)
    end
  end

  describe "to_iodata/1" do
    import Projection, only: [render: 3, to_iodata: 1]

    test "raises when rendered is not a list" do
      rendered = JSON.decode!("{}")

      assert_raise FunctionClauseError, fn ->
        to_iodata(rendered)
      end
    end

    test "writes nothing for an empty projection" do
      markup =
        []
        |> to_iodata()
        |> IO.iodata_to_binary()

      assert markup == ""
    end

    test "writes two nodes in document order" do
      document = %Document{
        root: [
          build_paragraph("n_aS5etBThqg3M", "Hello, world!"),
          build_paragraph("n_ChfDqDjlak39", "Goodbye, world!")
        ]
      }

      {rendered, []} = render(document, @blocks, :public)

      bytes =
        rendered
        |> to_iodata()
        |> IO.iodata_to_binary()

      assert bytes == "<p>Hello, world!</p><p>Goodbye, world!</p>"
    end
  end

  defmodule Reporting do
    use Masonree.Block

    @manifest %Manifest{name: "test/reporting", version: 1}

    @impl Masonree.Block
    def render(assigns) do
      rendered =
        ~H"""
        <aside {@html_attributes}>Reported!</aside>
        """

      {rendered, [:looked_fine]}
    end
  end

  defmodule Silent do
    use Masonree.Block

    @manifest %Manifest{name: "test/silent", version: 1}
  end

  defmodule Wrapping do
    use Masonree.Block

    @manifest %Manifest{name: "test/wrapping", version: 1}

    @impl Masonree.Block
    def render(assigns) do
      rendered =
        ~H"""
        <div {@html_attributes}>{render_slot(@inner_block)}</div>
        """

      {rendered, []}
    end
  end
end
