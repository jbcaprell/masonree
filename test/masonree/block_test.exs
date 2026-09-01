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

  describe "__before_compile__/1" do
    defmodule Registering do
      use Masonree.Block

      @manifest %Manifest{name: "test/registering", version: 1}
    end

    test "defines manifest/0 from the manifest the block registered" do
      assert Registering.manifest() ==
               %Masonree.Manifest{name: "test/registering", version: 1}
    end

    test "names every fault in one message, so four cost one compile" do
      message = ~r"""
      Masonree.BlockTest.Sprawling declares:
        - test-sprawling, which is not a namespaced block name
        - test-sprawling, whose tag attribute has an enum with no values\
      """

      assert_raise ArgumentError, message, fn ->
        defmodule Sprawling do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "tag" => %Attribute{role: :chrome, type: {:enum, []}}
            },
            name: "test-sprawling",
            version: 1
          }
        end
      end
    end

    test "refuses a block that registers no manifest" do
      message = ~r"Masonree.BlockTest.Unregistered must register @manifest"

      assert_raise ArgumentError, message, fn ->
        defmodule Unregistered do
          use Masonree.Block
        end
      end
    end

    test "refuses a manifest the validator rejects, naming the module first" do
      message =
        ~r"""
        Masonree.BlockTest.Misnamed declares Misnamed, which is not a \
        namespaced block name\
        """

      assert_raise ArgumentError, message, fn ->
        defmodule Misnamed do
          use Masonree.Block

          @manifest %Manifest{name: "Misnamed", version: 1}
        end
      end
    end

    test "returns the same term on every call" do
      assert :erts_debug.same(Registering.manifest(), Registering.manifest())
    end

    test "speaks bad_attribute_type in an author’s words" do
      message = ~r"whose tag attribute has a type outside the lattice"

      assert_raise ArgumentError, message, fn ->
        defmodule BadAttributeType do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{"tag" => %Attribute{role: :chrome, type: :bool}},
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks bad_key_format in an author’s words" do
      message = ~r/whose "tag name" attribute has a key of a refused shape/

      assert_raise ArgumentError, message, fn ->
        defmodule BadKeyFormat do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "tag name" => %Attribute{role: :chrome, type: :string}
            },
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks bad_version in an author’s words" do
      message = ~r"whose version is not a positive integer"

      assert_raise ArgumentError, message, fn ->
        defmodule BadVersion do
          use Masonree.Block

          @manifest %Manifest{name: "test/example", version: 0}
        end
      end
    end

    test "speaks default_outside_enum in an author’s words" do
      message = ~r"whose tag attribute has a default outside its own values"

      assert_raise ArgumentError, message, fn ->
        defmodule DefaultOutsideEnum do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "tag" => %Attribute{
                default: "h9",
                role: :chrome,
                type: {:enum, ["h2", "h3"]}
              }
            },
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks default_type_mismatch in an author’s words" do
      message = ~r"whose rank attribute has a default its type does not admit"

      assert_raise ArgumentError, message, fn ->
        defmodule DefaultTypeMismatch do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "rank" => %Attribute{default: "2", role: :chrome, type: :number}
            },
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks duplicate_enum_values in an author’s words" do
      message = ~r"whose tag attribute has repeated enum values"

      assert_raise ArgumentError, message, fn ->
        defmodule DuplicateEnumValues do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "tag" => %Attribute{role: :chrome, type: {:enum, ["h2", "h2"]}}
            },
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks non_string_keys in an author’s words" do
      message = ~r"whose attribute keys are not all strings"

      assert_raise ArgumentError, message, fn ->
        defmodule NonStringKeys do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{content: %Attribute{role: :content, type: :string}},
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks required_with_default in an author’s words" do
      message = ~r"whose src attribute has both a default and requiredness"

      assert_raise ArgumentError, message, fn ->
        defmodule RequiredWithDefault do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{
              "src" => %Attribute{
                default: "",
                required: true,
                role: :content,
                type: :string
              }
            },
            name: "test/example",
            version: 1
          }
        end
      end
    end

    test "speaks undeclared_role in an author’s words" do
      message =
        ~r"whose content attribute has no declared role, content or chrome"

      assert_raise ArgumentError, message, fn ->
        defmodule UndeclaredRole do
          use Masonree.Block

          @manifest %Manifest{
            attributes: %{"content" => %Attribute{type: :string}},
            name: "test/example",
            version: 1
          }
        end
      end
    end
  end

  describe "__using__/1" do
    defmodule Declaring do
      use Masonree.Block

      @manifest %Manifest{name: "test/declaring", version: 1}

      attr :rest, :global
      slot :inner_block, required: true

      @spec example(map()) :: Phoenix.LiveView.Rendered.t()
      def example(assigns) do
        ~H"""
        <div {@rest}>{render_slot(@inner_block)}</div>
        """
      end
    end

    defmodule Minimal do
      use Masonree.Block

      @manifest %Manifest{name: "test/minimal", version: 1}
    end

    defmodule Projecting do
      use Masonree.Block

      @manifest %Manifest{name: "test/projecting", version: 1}

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
