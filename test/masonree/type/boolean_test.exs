defmodule Masonree.Type.BooleanTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type.Boolean, import: true

  describe "admits?/2" do
    import Type.Boolean, only: [admits?: 2]

    test "takes a flag, and never its spelling" do
      assert admits?(nil, true)
      assert admits?(nil, false)
      refute admits?(nil, "true")
      refute admits?(nil, 1)
    end
  end

  describe "declarable?/1" do
    import Type.Boolean, only: [declarable?: 1]

    test "declares bare, and refuses any payload" do
      assert declarable?(nil)
      refute declarable?([])
      refute declarable?(true)
    end
  end

  describe "heal/3" do
    import Type.Boolean, only: [heal: 3]

    test "refuses, no second reading recovering the value" do
      assert heal(nil, ~C"junk", nil) == :refused
    end
  end
end
