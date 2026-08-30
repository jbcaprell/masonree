defmodule Masonree.NodeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Node

  doctest Node, import: true

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
