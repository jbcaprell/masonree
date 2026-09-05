defmodule Masonree.ReconciliationTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.8.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Reconciliation

  doctest Reconciliation, import: true

  describe "representable?/1" do
    import Reconciliation, only: [representable?: 1]

    test "admits the bytes a binary may carry, all but one" do
      assert representable?("tab\there")
      assert representable?("newline\nhere")
      assert representable?(<<0xFF, 0xFE>>)
    end

    test "admits the shapes the column holds exactly" do
      assert representable?(nil)
      assert representable?(true)
      assert representable?(2)
      assert representable?(2.5)
      assert representable?("Hello, world!")
      assert representable?(["Hello", 2, true])
      assert representable?(%{"level" => 2})
    end

    test "recurses, because depth restrings just as quietly" do
      assert representable?(%{"a" => [%{"b" => ["c"]}]})
      refute representable?(%{"a" => [%{"b" => [:c]}]})
    end

    test "refuses an atom key, which the column would restring" do
      refute representable?(%{level: 2})
    end

    test "refuses an atom value, which the column would restring" do
      refute representable?(:two)
    end

    test "refuses an integer key, which the column would restring" do
      refute representable?(%{1 => "one"})
    end

    test "refuses the NUL, which the column refuses outright" do
      refute representable?("null\0here")
    end
  end
end
