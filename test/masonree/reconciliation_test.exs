defmodule Masonree.ReconciliationTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.8.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Document
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

  describe "normalize/2" do
    import Reconciliation, only: [normalize: 2]

    test "drops what no declaration explains, and reports each" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!", "level" => 2},
            id: "n_L8oWETe9GxWK",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      {healed, problems} = normalize(document, manifests)
      [node] = healed.root

      assert node.attributes == %{}

      assert problems == [
               {:dropped_attribute, "n_L8oWETe9GxWK", "content"},
               {:dropped_attribute, "n_L8oWETe9GxWK", "level"}
             ]
    end

    test "heals at depth, the interior answering as the root does" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{
                children: [
                  %Node{
                    attributes: %{"content" => "Hello, world!"},
                    id: "n_uArvIJUM2y-J",
                    type: "test/example",
                    version: 1
                  }
                ],
                id: "n_JVLIhk9rl24m",
                type: "test/example",
                version: 1
              },
              %Node{id: "n_0gwrPRBEXfnK", type: "test/example", version: 1}
            ],
            id: "n_9nUkjK0eiKr9",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      {healed, problems} = normalize(document, manifests)
      [root] = healed.root
      [child, _sibling] = root.children
      [grandchild] = child.children

      assert grandchild.attributes == %{}
      assert problems == [{:dropped_attribute, "n_uArvIJUM2y-J", "content"}]
    end

    test "is idempotent, a healed document healing to itself" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!", "tag" => "h9"},
            id: "n_C2vNv-fBoV-A",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{
            "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
          },
          name: "test/example",
          version: 1
        }
      }

      {healed, [_dropped, _coerced]} = normalize(document, manifests)

      assert normalize(healed, manifests) == {healed, []}
    end

    test "leaves a refused value standing, unreported" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"flag" => "true"},
            id: "n_o5eqxcaCZzUY",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{"flag" => %Attribute{default: false, type: :boolean}},
          name: "test/example",
          version: 1
        }
      }

      {healed, problems} = normalize(document, manifests)
      [node] = healed.root

      assert node.attributes == %{"flag" => "true"}
      assert problems == []
    end

    test "preserves an unknown node exactly as it stands" do
      node = %Node{
        attributes: %{"content" => "Hello, world!", :odd => 2},
        id: "n_Wl4HxYYoVvA5",
        type: "test/rogue",
        version: 1
      }

      {healed, problems} = normalize(%Document{root: [node]}, %{})

      assert healed.root == [node]
      assert problems == [{:unrepresentable_attribute, "n_Wl4HxYYoVvA5", :odd}]
    end

    test "repairs a refused value toward the default, and reports it" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"tag" => "h9"},
            id: "n_wV-1z2eOe93x",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{
            "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
          },
          name: "test/example",
          version: 1
        }
      }

      {healed, problems} = normalize(document, manifests)
      [node] = healed.root

      assert node.attributes == %{"tag" => "h2"}
      assert problems == [{:coerced_attribute, "n_wV-1z2eOe93x", "tag"}]
    end

    test "sorts above the flat map's 32-key boundary" do
      attribute = fn index -> {"key-#{index}", index} end

      document = %Document{
        root: [
          %Node{
            attributes: Map.new(1..40, attribute),
            id: "n_Qr6b9HsQBITi",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      {_healed, problems} = normalize(document, manifests)

      assert length(problems) == 40
      assert problems == Enum.sort(problems)
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
