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
end
