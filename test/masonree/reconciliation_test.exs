defmodule Masonree.ReconciliationTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.8.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Node
  alias Masonree.Reconciliation

  doctest Reconciliation, import: true

  describe "put_default/3" do
    import Reconciliation, only: [put_default: 3]

    test "leaves a nil default unwritten, absence being the declaration" do
      assert put_default(%{}, "content", nil) == %{}
    end

    test "never overwrites a value already held" do
      assert put_default(%{"tag" => "h3"}, "tag", "h2") == %{"tag" => "h3"}
    end

    test "writes the default where the key is absent" do
      assert put_default(%{}, "tag", "h2") == %{"tag" => "h2"}
    end
  end

  describe "report_unrepresentable/1" do
    import Reconciliation, only: [report_unrepresentable: 1]

    test "carries the offending key exactly as found" do
      node = %Node{
        attributes: %{1 => "one", :level => 2},
        id: "n_2NZ9blnBmO23",
        type: "test/example",
        version: 1
      }

      assert report_unrepresentable(node) == [
               {:unrepresentable_attribute, "n_2NZ9blnBmO23", 1},
               {:unrepresentable_attribute, "n_2NZ9blnBmO23", :level}
             ]
    end

    test "judges the value beneath a well-formed key" do
      node = %Node{
        attributes: %{"content" => "null\0here"},
        id: "n_2NZ9blnBmO23",
        type: "test/example",
        version: 1
      }

      assert report_unrepresentable(node) ==
               [{:unrepresentable_attribute, "n_2NZ9blnBmO23", "content"}]
    end

    test "reports nothing where every entry is representable" do
      node = %Node{
        attributes: %{"content" => "Hello, world!", "level" => 2},
        id: "n_2NZ9blnBmO23",
        type: "test/example",
        version: 1
      }

      assert report_unrepresentable(node) == []
    end
  end

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
