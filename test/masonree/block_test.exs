defmodule Masonree.BlockTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Node

  doctest Block, import: true

  describe "Block" do
    test "asks every block for a manifest and only some for markup" do
      callbacks = Block.behaviour_info(:callbacks)

      assert Enum.sort(callbacks) == [manifest: 0, render: 1]
      assert Block.behaviour_info(:optional_callbacks) == [render: 1]
    end
  end

  describe "__using__/1" do
    defmodule Declaring do
      use Masonree.Block

      attr :rest, :global
      slot :inner_block, required: true

      @spec example(map()) :: Phoenix.LiveView.Rendered.t()
      def example(assigns) do
        ~H"""
        <div {@rest}>{render_slot(@inner_block)}</div>
        """
      end

      @impl Block
      def manifest(), do: %Manifest{name: "test/declaring", version: 1}
    end

    defmodule Minimal do
      use Masonree.Block

      @impl Block
      def manifest(), do: %Manifest{name: "test/minimal", version: 1}
    end

    defmodule Projecting do
      use Masonree.Block

      @impl Block
      def manifest(), do: %Manifest{name: "test/projecting", version: 1}

      @impl Block
      def render(assigns) do
        assigns = assign(assigns, :content, assigns.node.attributes["content"])

        rendered =
          ~H"""
          <div>{@content}</div>
          """

        {rendered, []}
      end
    end

    test "gives a block ~H for its markup" do
      assigns = %{
        __changed__: nil,
        node: %Node{
          attributes: %{"content" => "<strong>Hello, world!</strong>"},
          id: "n_m3FI_Zg5h3MW",
          type: "test/projecting",
          version: 1
        }
      }

      {rendered, []} = Projecting.render(assigns)

      markup =
        rendered
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert markup == ~S(<div>&lt;strong&gt;Hello, world!&lt;/strong&gt;</div>)
    end

    test "lets a block declare attributes on its own components" do
      %{attrs: attrs, slots: slots} = Declaring.__components__()[:example]

      assert Enum.map(attrs, & &1.name) == [:rest]
      assert Enum.map(slots, & &1.name) == [:inner_block]
    end

    test "registers the behaviour on the block" do
      attributes = Minimal.__info__(:attributes)

      assert attributes[:behaviour] == [Block]
    end
  end
end
