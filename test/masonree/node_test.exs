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
end
