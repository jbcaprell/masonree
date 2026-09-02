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

  @spec build_paragraph(Node.id(), String.t(), nil | String.t()) :: Node.t()
  defp build_paragraph(id, content, preset \\ nil) do
    %Node{
      attributes: %{"content" => content},
      id: id,
      preset: preset,
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

      assert to_markup(rendered) ==
               ~S(<p data-mnr="paragraph">Hello, world!</p>)

      assert problems == [
               {:unknown_block, "n_tBhgl2qwXA7K"},
               {:unrenderable_block, "n_58CfR-5sI0EM"}
             ]
    end

    test "annotates an editor’s page too" do
      document = %Document{
        root: [build_paragraph("n_VTS22gkaQ6HW", "Hello, world!")]
      }

      {rendered, []} = render(document, @blocks, :editor)

      assert to_markup(rendered) ==
               ~S(<p data-mnr="paragraph" data-mnr-id="n_VTS22gkaQ6HW">) <>
                 ~S(Hello, world!</p>)
    end

    test "carries a block’s own findings, stamped with its id" do
      document = %Document{
        root: [%Node{id: "n_IJh1GqtyfU8b", type: "test/reporting", version: 1}]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) ==
               ~S(<aside data-mnr="reporting">Reported!</aside>)

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

      assert to_markup(rendered) ==
               ~S(<div data-mnr="wrapping">) <>
                 ~S(<p data-mnr="paragraph">Hello, world!</p></div>)
    end

    test "descends, so a child’s problem surfaces" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{id: "n_tBhgl2qwXA7K", type: "test/gone", version: 1}
            ],
            id: "n_ZazV3ZSV4fVV",
            type: "test/wrapping",
            version: 1
          }
        ]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) == ~S(<div data-mnr="wrapping"></div>)
      assert problems == [{:unknown_block, "n_tBhgl2qwXA7K"}]
    end

    test "discards the interior of a block that declares none" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!"},
            children: [build_paragraph("n_NX3_-SiYDOeK", "Goodbye, world!")],
            id: "n_ZazV3ZSV4fVV",
            type: "core/paragraph",
            version: 1
          }
        ]
      }

      {rendered, problems} = render(document, @blocks, :public)

      assert to_markup(rendered) ==
               ~S(<p data-mnr="paragraph">Hello, world!</p>)

      assert problems == [{:discarded_interior, "n_ZazV3ZSV4fVV"}]
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

      assert to_markup(rendered) ==
               ~S(<p data-mnr="paragraph">Hello, world!</p>) <>
                 ~S(<p data-mnr="paragraph">Goodbye, world!</p>)

      assert problems == [{:unknown_block, "n_tBhgl2qwXA7K"}]
    end

    test "marks every node of a nest in :editor, not only the root" do
      document = %Document{
        root: [
          %Node{
            children: [build_paragraph("n_VTS22gkaQ6HW", "Hello, world!")],
            id: "n_SXo9U3MZlxK1",
            type: "test/wrapping",
            version: 1
          }
        ]
      }

      {rendered, []} = render(document, @blocks, :editor)

      assert to_markup(rendered) =~ ~S(data-mnr-id="n_SXo9U3MZlxK1")
      assert to_markup(rendered) =~ ~S(data-mnr-id="n_VTS22gkaQ6HW")
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

    test "writes a preset beside the local name" do
      document = %Document{
        root: [
          build_paragraph("n_VTS22gkaQ6HW", "Hello, world!", "intro"),
          build_paragraph("n_aS5etBThqg3M", "Goodbye, world!", "outro")
        ]
      }

      {rendered, []} = render(document, @blocks, :public)

      assert to_markup(rendered) ==
               ~S(<p data-mnr="paragraph" ) <>
                 ~S(data-mnr-preset="intro">Hello, world!</p>) <>
                 ~S(<p data-mnr="paragraph" ) <>
                 ~S(data-mnr-preset="outro">Goodbye, world!</p>)
    end

    test "writes no identity in :public" do
      document = %Document{
        root: [build_paragraph("n_VTS22gkaQ6HW", "Hello, world!")]
      }

      {rendered, []} = render(document, @blocks, :public)

      refute to_markup(rendered) =~ "data-mnr-id"
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

      assert bytes ==
               ~S(<p data-mnr="paragraph">Hello, world!</p>) <>
                 ~S(<p data-mnr="paragraph">Goodbye, world!</p>)
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

    @manifest %Manifest{
      containment: %Manifest.Containment{},
      name: "test/wrapping",
      version: 1
    }

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
