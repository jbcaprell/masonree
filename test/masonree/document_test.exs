defmodule Masonree.DocumentTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Document
  alias Masonree.Node

  doctest Document, import: true

  @document %Document{
    root: [
      %Node{
        children: [
          %Node{
            children: [
              %Node{id: "n_1ARgI7WIP_25", type: "test/example", version: 1},
              %Node{id: "n_OcoZyidcF1tM", type: "test/example", version: 1}
            ],
            id: "n_0LofVPj0Ujl0",
            type: "test/example",
            version: 1
          },
          %Node{id: "n_THJxr_DEBbEe", type: "test/example", version: 1}
        ],
        id: "n_51LPnq3SM3uh",
        type: "test/example",
        version: 1
      },
      %Node{
        attributes: %{"level" => 3},
        id: "n_qP7DjHPA5X2J",
        type: "test/example",
        version: 1
      }
    ]
  }

  @spec build_bare(pos_integer()) :: Node.serialized()
  defp build_bare(1), do: %{"type" => "test/example"}

  defp build_bare(levels) do
    children = for _child <- 1..3, do: build_bare(levels - 1)

    %{"children" => children, "type" => "test/example"}
  end

  @spec descend(Node.t()) :: [Node.t()]
  defp descend(node) do
    [node | Enum.flat_map(node.children, &descend/1)]
  end

  @spec flatten(Document.t()) :: [Node.t()]
  defp flatten(document), do: Enum.flat_map(document.root, &descend/1)

  describe "%Document{}" do
    test "is an empty root and nothing else" do
      assert Map.from_struct(%Document{}) == %{root: []}
    end
  end

  describe "from_map!/1" do
    import Document, only: [from_map!: 1]

    test "fills every absence" do
      assert from_map!(%{}) == %Document{root: []}
    end

    test "raises on a document that is not a map" do
      serialized = JSON.decode!("\"n_5Y3sMqERkI2m\"")

      assert_raise FunctionClauseError, fn -> from_map!(serialized) end
    end

    test "raises on a root entry that is not a node" do
      serialized = %{"root" => [%{"kind" => "test/example"}]}

      assert_raise FunctionClauseError, fn -> from_map!(serialized) end
    end

    test "raises on a struct, which is a map and not an envelope" do
      [serialized] = Enum.take([%Document{}], 1)

      assert_raise FunctionClauseError, fn -> from_map!(serialized) end
    end

    test "round-trips a nested document exactly" do
      serialized = Document.to_map(@document)

      assert from_map!(serialized) == @document
    end

    test "round-trips a page-sized document exactly" do
      root = for _root <- 1..3, do: build_bare(5)
      document = from_map!(%{"root" => root})
      nodes = flatten(document)
      written = Document.to_map(document)

      assert length(nodes) == 363
      assert length(document.root) == 3
      assert from_map!(written) == document
    end

    test "treats a malformed root value as absent" do
      serialized = %{
        "root" => %{"id" => "n_KuCOuIHzdILO", "type" => "test/example"}
      }

      assert from_map!(serialized) == %Document{root: []}
    end
  end

  describe "from_map/1" do
    import Document, only: [from_map: 1]

    test "reads a well-formed document, root in written order" do
      serialized = %{
        "root" => [
          %{"id" => "n_tjt_RqeMme7S", "type" => "test/example"},
          %{"id" => "n_CFPw-OJU3X68", "type" => "test/example"}
        ]
      }

      {:ok, document} = from_map(serialized)

      assert document == Document.from_map!(serialized)

      assert Enum.map(document.root, & &1.id) ==
               ~W[n_tjt_RqeMme7S n_CFPw-OJU3X68]
    end

    test "refuses a root entry at depth that is not an envelope" do
      serialized = %{
        "root" => [%{"children" => [%{}], "type" => "test/example"}]
      }

      assert from_map(serialized) == :error
    end

    test "refuses a root entry that is not a node" do
      assert from_map(%{"root" => [%{}]}) == :error
    end

    test "refuses a shape that is not a map" do
      assert from_map([]) == :error
    end

    test "refuses a struct, which is a map and not an envelope" do
      node = %Node{id: "n_62310XrXypQB", type: "test/example", version: 1}

      assert from_map(%Document{root: [node]}) == :error
      assert from_map(node) == :error
    end

    test "tolerates a malformed root, as the raising reader does" do
      assert from_map(%{"root" => "none"}) == {:ok, %Document{root: []}}
    end
  end

  describe "to_map/1" do
    import Document, only: [to_map: 1]

    test "raises on anything that is not a document" do
      serialized = JSON.decode!("{}")

      assert_raise FunctionClauseError, fn -> to_map(serialized) end
    end

    test "writes an empty root for an empty document" do
      assert to_map(%Document{}) == %{"root" => []}
    end

    test "writes each node through the node’s own writer" do
      [node, _child] = @document.root

      [serialized, _child] = to_map(@document)["root"]

      assert serialized == Node.to_map(node)
    end

    test "writes every key as a string" do
      keys =
        @document
        |> to_map()
        |> Map.keys()

      assert Enum.all?(keys, &is_binary/1)
    end

    test "writes every root node, in order" do
      serialized = to_map(@document)

      assert Enum.map(serialized["root"], & &1["id"]) ==
               ~W[n_51LPnq3SM3uh n_qP7DjHPA5X2J]
    end
  end
end
