defmodule Masonree.Type.EnumTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type.Enum, import: true

  describe "admits?/2" do
    import Type.Enum, only: [admits?: 2]

    test "answers membership of the declared list, whatever it holds" do
      assert admits?(["dark", "light"], "dark")
      assert admits?([1, 2, 3, "auto"], "auto")
      refute admits?(["dark", "light"], "vermilion")
      refute admits?([], "dark")
    end

    test "compares by identity, never by spelling" do
      refute admits?(["dark", "light"], :dark)
      refute admits?(["dark", "light"], "Dark")
      refute admits?([1], 1.0)
    end

    test "refuses everything when the payload is not a list" do
      refute admits?(nil, "dark")
      refute admits?("dark", "dark")
    end
  end

  describe "declarable?/1" do
    import Type.Enum, only: [declarable?: 1]

    test "declares with a list, and refuses everything else" do
      assert declarable?([])
      assert declarable?(["dark", "light"])
      refute declarable?(nil)
      refute declarable?("dark")
    end
  end

  describe "heal/3" do
    import Type.Enum, only: [heal: 3]

    test "falls back to the declared default, whatever the value" do
      assert heal(["dark", "light"], "vermilion", "dark") == {:coerced, "dark"}
    end
  end
end
