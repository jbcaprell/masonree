defmodule Masonree.Type.NumberTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type.Number, import: true

  describe "admits?/2" do
    import Type.Number, only: [admits?: 2]

    test "takes an integer and a float, undivided" do
      assert admits?(nil, 3)
      assert admits?(nil, 1.5)
      refute admits?(nil, "3")
      refute admits?(nil, true)
    end
  end

  describe "declarable?/1" do
    import Type.Number, only: [declarable?: 1]

    test "declares bare, and refuses any payload" do
      assert declarable?(nil)
      refute declarable?([])
      refute declarable?(0)
    end
  end

  describe "heal/3" do
    import Type.Number, only: [heal: 3]

    test "refuses, no second reading recovering the value" do
      assert heal(nil, ~C"junk", nil) == :refused
    end
  end
end
