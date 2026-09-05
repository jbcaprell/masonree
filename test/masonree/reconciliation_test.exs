defmodule Masonree.ReconciliationTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.8.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest
  alias Masonree.Node
  alias Masonree.Reconciliation

  alias Manifest.Attribute

  doctest Reconciliation, import: true

  describe "fill_defaults/2" do
    import Reconciliation, only: [fill_defaults: 2]

    test "fills every declared default the node left absent" do
      declarations = %{
        "content" => %Attribute{default: "", role: :content, type: :string},
        "tag" => %Attribute{default: "h2", role: :chrome, type: :string}
      }

      assert fill_defaults(%{}, declarations) ==
               %{"content" => "", "tag" => "h2"}
    end

    test "keeps every value it was given" do
      attributes = %{"content" => "Hello, world!", "level" => 2}

      declarations = %{
        "content" => %Attribute{default: "", role: :content, type: :string}
      }

      assert fill_defaults(attributes, declarations) == attributes
    end

    test "leaves a nil default unwritten through the fold" do
      declarations = %{"tag" => %Attribute{role: :chrome, type: :string}}

      assert fill_defaults(%{}, declarations) == %{}
    end
  end

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

  describe "report_dropped/2" do
    import Reconciliation, only: [report_dropped: 2]

    test "names each key the manifest does not declare" do
      node = %Node{
        attributes: %{"content" => "Hello, world!", "level" => 2},
        id: "n_5oFH-2ZgNhL8",
        type: "test/example",
        version: 1
      }

      assert report_dropped(node, %{}) == [
               {:dropped_attribute, "n_5oFH-2ZgNhL8", "content"},
               {:dropped_attribute, "n_5oFH-2ZgNhL8", "level"}
             ]
    end

    test "reports nothing for a node holding no attributes" do
      node = %Node{id: "n_5oFH-2ZgNhL8", type: "test/example", version: 1}

      assert report_dropped(node, %{}) == []
    end

    test "reports nothing where every key is declared" do
      node = %Node{
        attributes: %{"content" => "Hello, world!"},
        id: "n_5oFH-2ZgNhL8",
        type: "test/example",
        version: 1
      }

      declarations = %{"content" => %Attribute{role: :content, type: :string}}

      assert report_dropped(node, declarations) == []
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

  describe "take_declared/2" do
    import Reconciliation, only: [take_declared: 2]

    test "keeps every declared key, whatever it holds" do
      attributes = %{"content" => "Hello, world!", "tag" => 2}

      declarations = %{
        "content" => %Attribute{role: :content, type: :string},
        "tag" => %Attribute{role: :chrome, type: :string}
      }

      assert take_declared(attributes, declarations) == attributes
    end

    test "removes every key no declaration explains" do
      attributes = %{"content" => "Hello, world!", "level" => 2, "tag" => "h2"}

      declarations = %{"content" => %Attribute{role: :content, type: :string}}

      assert take_declared(attributes, declarations) ==
               %{"content" => "Hello, world!"}
    end
  end

  describe "take_repairs/2" do
    import Reconciliation, only: [take_repairs: 2]

    test "leaves a held nil alone, the lattice admitting it" do
      declarations = %{
        "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
      }

      assert take_repairs(%{"tag" => nil}, declarations) == []
    end

    test "leaves a refused value out, filtered by construction" do
      declarations = %{
        "flag" => %Attribute{default: false, type: :boolean}
      }

      assert take_repairs(%{"flag" => "true"}, declarations) == []
    end

    test "leaves an admitted value alone, whoever held it" do
      declarations = %{
        "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
      }

      assert take_repairs(%{"tag" => "h3"}, declarations) == []
    end

    test "owes the member's coercion where the type refuses the value" do
      declarations = %{
        "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
      }

      assert take_repairs(%{"tag" => "h9"}, declarations) ==
               [{:coerced, "tag", "h2"}]
    end
  end

  describe "write_repair/2" do
    import Reconciliation, only: [write_repair: 2]

    test "deletes the key where the healed value is nil" do
      assert write_repair(%{"tag" => "h9"}, {"tag", nil}) == %{}
    end

    test "folds, so many repairs write one map" do
      repairs = [{"level", 2}, {"tag", nil}]
      attributes = %{"level" => "two", "tag" => "h9"}
      write = fn repair, acc -> write_repair(acc, repair) end

      assert Enum.reduce(repairs, attributes, write) == %{"level" => 2}
    end

    test "replaces the held value with the healed one" do
      assert write_repair(%{"tag" => "h9"}, {"tag", "h2"}) == %{"tag" => "h2"}
    end
  end
end
