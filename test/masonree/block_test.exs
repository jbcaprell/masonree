defmodule Masonree.BlockTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block

  doctest Block, import: true

  describe "Block" do
    test "asks every block for a manifest and only some for markup" do
      callbacks = Block.behaviour_info(:callbacks)

      assert Enum.sort(callbacks) == [manifest: 0, render: 1]
      assert Block.behaviour_info(:optional_callbacks) == [render: 1]
    end
  end
end
