defmodule Masonree.Type.StringTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type.String, import: true

  describe "admits?/2" do
    import Type.String, only: [admits?: 2]

    test "takes text, and markup in it is text" do
      assert admits?(nil, "Hello, world!")
      assert admits?(nil, "<strong>Hello, world!</strong>")
      assert admits?(nil, "")
      refute admits?(nil, ~C"Hello, world!")
      refute admits?(nil, :hello)
    end
  end

  describe "declarable?/1" do
    import Type.String, only: [declarable?: 1]

    test "declares bare, and refuses any payload" do
      assert declarable?(nil)
      refute declarable?([])
      refute declarable?("")
    end
  end

  describe "heal/3" do
    import Type.String, only: [heal: 3]

    test "refuses, no second reading recovering the value" do
      assert heal(nil, ~C"junk", nil) == :refused
    end
  end
end
