defmodule Masonree.NodeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Node

  doctest Node, import: true

  @spec build_bare(pos_integer()) :: Node.serialized()
  defp build_bare(1), do: %{"type" => "test/example"}

  defp build_bare(levels) do
    children = for _child <- 1..3, do: build_bare(levels - 1)

    %{"children" => children, "type" => "test/example"}
  end

  @spec flatten(Node.t()) :: [Node.t()]
  defp flatten(node) do
    descendants = Enum.flat_map(node.children, &flatten/1)

    [node | descendants]
  end

  describe "%Node{}" do
    test "defaults to no attributes, children or preset" do
      node = %Node{id: "n_Kx2c80c5vMx_", type: "test/example", version: 1}

      assert Map.from_struct(node) == %{
               attributes: %{},
               children: [],
               id: "n_Kx2c80c5vMx_",
               preset: nil,
               type: "test/example",
               version: 1
             }
    end

    test "enforces an id, a type and a version" do
      message = ~r"must also be given .*: \[:id, :type, :version\]"

      assert_raise ArgumentError, message, fn -> struct!(Node, []) end
    end
  end

  describe "from_map!/1" do
    import Node, only: [from_map!: 1]

    test "fills every absence" do
      node = from_map!(%{"type" => "test/example"})

      assert node.attributes == %{}
      assert node.children == []
      assert node.id =~ ~r"^n_[A-Za-z0-9_-]{12}$"
      assert node.preset == nil
      assert node.version == 1
    end

    test "mints over a malformed id value" do
      node = from_map!(%{"id" => 123, "type" => "test/example"})

      assert node.id =~ ~r"^n_[A-Za-z0-9_-]{12}$"
    end

    test "raises on a child that is not a serialized node" do
      serialized = %{"children" => [123], "type" => "test/example"}

      assert_raise FunctionClauseError, fn -> from_map!(serialized) end
    end

    test "raises on a node that is not a map" do
      serialized = JSON.decode!("\"n_lLCyp2yRS20A\"")

      assert_raise FunctionClauseError, fn -> from_map!(serialized) end
    end

    test "raises on a type that is not a string" do
      assert_raise FunctionClauseError, fn ->
        from_map!(%{"type" => 1})
      end
    end

    test "raises when no type is named" do
      assert_raise FunctionClauseError, fn -> from_map!(%{}) end
    end

    test "reads a page-sized tree whole" do
      nodes =
        6
        |> build_bare()
        |> from_map!()
        |> flatten()

      ids = Enum.map(nodes, & &1.id)

      assert length(nodes) == 364
      assert Enum.all?(ids, &(&1 =~ ~r"^n_[A-Za-z0-9_-]{12}$"))
      assert ids == Enum.uniq(ids)
    end

    test "reads the children too" do
      serialized =
        %{
          "children" => [%{"id" => "n_ddcbzgItwMEo", "type" => "test/example"}],
          "type" => "test/example"
        }

      node = from_map!(serialized)

      assert [%Node{id: "n_ddcbzgItwMEo", type: "test/example"}] = node.children
    end

    test "round-trips a nested node exactly" do
      serialized =
        Node.to_map(%Node{
          attributes: %{"content" => ""},
          children: [
            %Node{
              attributes: %{"level" => 3},
              children: [
                %Node{
                  id: "n_LShU-G52tUje",
                  preset: "grandchild",
                  type: "test/example",
                  version: 3
                }
              ],
              id: "n_hFn-vNDFczWN",
              preset: "child",
              type: "test/example",
              version: 2
            }
          ],
          id: "n_fXmu96rWPc2k",
          type: "test/section",
          version: 1
        })

      node = from_map!(serialized)

      assert Node.to_map(node) == serialized
    end

    test "treats a malformed attributes value as absent" do
      node = from_map!(%{"attributes" => "content", "type" => "test/example"})

      assert node.attributes == %{}
    end

    test "treats a malformed children value as absent" do
      serialized = %{
        "children" => %{"id" => "n_3LiBstWPCLMC", "type" => "test/child"},
        "type" => "test/example"
      }

      node = from_map!(serialized)

      assert node.children == []
    end

    test "treats a malformed preset value as absent" do
      node = from_map!(%{"preset" => ["wide"], "type" => "test/example"})

      assert node.preset == nil
    end

    test "treats a malformed version value as absent" do
      node = from_map!(%{"type" => "test/example", "version" => %{"n" => 2}})

      assert node.version == 1
    end

    test "treats a version below 1 as absent" do
      assert from_map!(%{"type" => "test/example", "version" => 0}).version == 1
    end
  end

  describe "from_map/1" do
    import Node, only: [from_map: 1]

    test "reads a well-formed envelope" do
      serialized = %{
        "attributes" => %{"level" => 3},
        "children" => [%{"id" => "n_3LiBstWPCLMC", "type" => "test/child"}],
        "id" => "n_Fr5MmRIUVz2F",
        "preset" => "wide",
        "type" => "test/example",
        "version" => 2
      }

      assert from_map(serialized) == {:ok, Node.from_map!(serialized)}
    end

    test "refuses a child at depth that is not an envelope" do
      grandchild = %{"id" => "n_3LiBstWPCLMC"}
      child = %{"children" => [grandchild], "type" => "test/example"}
      serialized = %{"children" => [child], "type" => "test/example"}

      assert from_map(serialized) == :error
    end

    test "refuses a map with no type" do
      assert from_map(%{"id" => "n_wJEY6cpelYvh"}) == :error
    end

    test "refuses a type that is not a string" do
      assert from_map(%{"type" => 42}) == :error
    end

    test "tolerates a malformed field, as the raising reader does" do
      serialized = %{
        "children" => "none",
        "id" => 123,
        "type" => "test/example"
      }

      {:ok, node} = from_map(serialized)

      assert node.children == []
      assert node.id != 123
    end
  end

  describe "generate_id/0" do
    import Node, only: [generate_id: 0]

    test "mints a different id every time" do
      ids = for _sample <- 1..100, do: generate_id()

      assert Enum.uniq(ids) == ids
    end

    test "mints an id that decodes to nine bytes" do
      "n_" <> encoded = generate_id()
      entropy = Base.url_decode64!(encoded, padding: false)

      assert byte_size(entropy) == 9
    end

    test "mints an id that is url-safe" do
      ids = for _sample <- 1..100, do: generate_id()

      assert Enum.all?(ids, &(&1 =~ ~r"^n_[A-Za-z0-9_-]{12}$"))
    end
  end

  describe "to_map/1" do
    import Node, only: [to_map: 1]

    test "raises on anything that is not a node" do
      serialized = JSON.decode!("{}")

      assert_raise FunctionClauseError, fn -> to_map(serialized) end
    end

    test "writes a nil preset rather than omitting it" do
      node = %Node{id: "n_gTYItXZZjaGz", type: "test/example", version: 1}

      assert to_map(node) == %{
               "attributes" => %{},
               "children" => [],
               "id" => "n_gTYItXZZjaGz",
               "preset" => nil,
               "type" => "test/example",
               "version" => 1
             }
    end

    test "writes a preset and attributes as the node holds them" do
      node = %Node{
        attributes: %{"level" => 2},
        id: "n_52w2MXyS-kCm",
        preset: "wide",
        type: "test/section",
        version: 2
      }

      assert to_map(node) == %{
               "attributes" => %{"level" => 2},
               "children" => [],
               "id" => "n_52w2MXyS-kCm",
               "preset" => "wide",
               "type" => "test/section",
               "version" => 2
             }
    end

    test "writes every key as a string" do
      keys =
        %Node{id: "n_OQp1PpCDitq2", type: "test/example", version: 1}
        |> to_map()
        |> Map.keys()

      assert Enum.all?(keys, &is_binary/1)
    end

    test "writes the children too" do
      child = %Node{id: "n_ZQzWpnIxBaGx", type: "test/example", version: 1}

      node = %Node{
        children: [child],
        id: "n_pCJ09Qmp_iAI",
        type: "test/example",
        version: 1
      }

      assert to_map(node)["children"] == [to_map(child)]
    end
  end
end
