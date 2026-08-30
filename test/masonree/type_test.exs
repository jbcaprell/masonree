defmodule Masonree.TypeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type, import: true

  describe "Type" do
    test "the lattice asks one question, and every member must answer" do
      assert Type.behaviour_info(:callbacks) == [admits?: 2]
      assert Type.behaviour_info(:optional_callbacks) == []
    end
  end

  describe "admits?/2" do
    import Type, only: [admits?: 2]

    test "puts the question to the member" do
      assert admits?(:boolean, true)
      refute admits?(:boolean, "true")

      assert admits?(:number, 3)
      refute admits?(:number, "3")

      assert admits?(:string, "Hello, world!")
      refute admits?(:string, ~C"Hello, world!")

      assert admits?({:enum, ["dark", "light"]}, "dark")
      refute admits?({:enum, ["dark", "light"]}, "vermilion")
    end

    test "refuses a type the lattice does not hold" do
      refute admits?(:bool, true)
      refute admits?({:bool, true}, true)
      refute admits?("boolean", true)
      refute admits?("boolean", "true")
    end

    test "returns true for a nil, whatever the type" do
      assert admits?(:boolean, nil)
      assert admits?(:bool, nil)
    end
  end

  describe "list_tags/0" do
    import Type, only: [list_tags: 0]

    test "returns every tag the lattice holds, sorted" do
      assert list_tags() == ~W[boolean enum number string]a
    end
  end
end
