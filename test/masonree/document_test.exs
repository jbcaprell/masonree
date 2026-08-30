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

  describe "%Document{}" do
    test "is an empty root and nothing else" do
      assert Map.from_struct(%Document{}) == %{root: []}
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
