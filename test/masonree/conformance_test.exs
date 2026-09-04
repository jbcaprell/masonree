defmodule Masonree.ConformanceTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.7.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Conformance
  alias Masonree.Document
  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Attribute
  alias Manifest.Containment

  doctest Conformance, import: true

  describe "validate/2" do
    import Conformance, only: [validate: 2]

    test "finds a problem at depth exactly as at the root" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{
                children: [
                  %Node{id: "n_x9y2vGeqrb-J", type: "test/rogue", version: 1}
                ],
                id: "n_o3qL6MOd0Vjq",
                type: "test/example",
                version: 1
              },
              %Node{id: "n_V6BiFB09kmO4", type: "test/example", version: 1}
            ],
            id: "n_kn9M2iVCbYUO",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      assert validate(document, manifests) ==
               [{:unknown_block, "n_x9y2vGeqrb-J"}]
    end

    test "keeps document order across depths" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{
                attributes: %{"content" => "Hello, world!"},
                id: "n_o3qL6MOd0Vjq",
                type: "test/example",
                version: 1
              }
            ],
            id: "n_kn9M2iVCbYUO",
            type: "test/example",
            version: 1
          },
          %Node{id: "n_V6BiFB09kmO4", type: "test/rogue", version: 1}
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      assert validate(document, manifests) == [
               {:unknown_attribute, "n_o3qL6MOd0Vjq", "content"},
               {:unknown_block, "n_V6BiFB09kmO4"}
             ]
    end

    test "reports a conforming page clean" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{
                attributes: %{"content" => "Hello, world!"},
                id: "n_o3qL6MOd0Vjq",
                type: "test/example",
                version: 1
              }
            ],
            id: "n_kn9M2iVCbYUO",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{"content" => %Attribute{role: :content, type: :string}},
          containment: %Containment{},
          name: "test/example",
          version: 1
        }
      }

      assert validate(document, manifests) == []
    end

    test "reports an empty document clean" do
      assert validate(%Document{}, %{}) == []
    end

    test "reports an unknown block alone, attributes unjudged" do
      document = %Document{
        root: [
          %Node{
            attributes: %{123 => :junk, "level" => "not-even-wrong"},
            id: "n_pRWK-vNzXQjm",
            type: "test/rogue",
            version: 1
          }
        ]
      }

      assert validate(document, %{}) == [{:unknown_block, "n_pRWK-vNzXQjm"}]
    end

    test "reports an unknown block at depth once, not a cascade" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{
                children: [
                  %Node{
                    attributes: %{"junk" => true},
                    id: "n_x9y2vGeqrb-J",
                    type: "test/rogue",
                    version: 1
                  }
                ],
                id: "n_o3qL6MOd0Vjq",
                type: "test/example",
                version: 1
              }
            ],
            id: "n_kn9M2iVCbYUO",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      assert validate(document, manifests) ==
               [{:unknown_block, "n_x9y2vGeqrb-J"}]
    end

    test "reports every attribute fault, sorted" do
      document = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!", "rank" => "2"},
            id: "n_pRWK-vNzXQjm",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{
            "rank" => %Attribute{role: :chrome, type: :number},
            "src" => %Attribute{required: true, role: :content, type: :string}
          },
          name: "test/example",
          version: 1
        }
      }

      assert validate(document, manifests) == [
               {:bad_attribute_value, "n_pRWK-vNzXQjm", "rank"},
               {:missing_attribute, "n_pRWK-vNzXQjm", "src"},
               {:unknown_attribute, "n_pRWK-vNzXQjm", "content"}
             ]
    end

    test "reports the interior beside the attributes, count first" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{id: "n_Mk3PjLYVpuGI", type: "test/plain", version: 1}
            ],
            id: "n_pRWK-vNzXQjm",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{
            "src" => %Attribute{required: true, role: :content, type: :string}
          },
          containment: %Containment{allowed: ["test/example"], minimum: 2},
          name: "test/example",
          version: 1
        },
        "test/plain" => %Manifest{name: "test/plain", version: 1}
      }

      assert validate(document, manifests) == [
               {:too_few_children, "n_pRWK-vNzXQjm"},
               {:missing_attribute, "n_pRWK-vNzXQjm", "src"},
               {:refused_child, "n_pRWK-vNzXQjm", "n_Mk3PjLYVpuGI"}
             ]
    end

    test "sorts a node's findings whole, refused children by child id" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{id: "n_HpprvB0V-4aB", type: "test/plain", version: 1},
              %Node{id: "n_Cy2VLEr1M6t9", type: "test/plain", version: 1}
            ],
            id: "n_pRWK-vNzXQjm",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{
          containment: %Containment{allowed: ["test/example"]},
          name: "test/example",
          version: 1
        },
        "test/plain" => %Manifest{name: "test/plain", version: 1}
      }

      assert validate(document, manifests) == [
               {:refused_child, "n_pRWK-vNzXQjm", "n_Cy2VLEr1M6t9"},
               {:refused_child, "n_pRWK-vNzXQjm", "n_HpprvB0V-4aB"}
             ]
    end

    test "sorts above the flat map's 32-key boundary" do
      attribute = fn index -> {"key-#{index}", index} end

      document = %Document{
        root: [
          %Node{
            attributes: Map.new(1..40, attribute),
            id: "n_pRWK-vNzXQjm",
            type: "test/example",
            version: 1
          }
        ]
      }

      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      report = validate(document, manifests)

      assert length(report) == 40
      assert report == Enum.sort(report)
    end
  end

  describe "validate_admission/2" do
    import Conformance, only: [validate_admission: 2]

    test "admits any interior where no containment is declared" do
      node = %Node{
        children: [%Node{id: "n_Mk3PjLYVpuGI", type: "test/rogue", version: 1}],
        id: "n_QjR9Ni9nMkzO",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_admission(node, manifest) == []
    end

    test "admits every child where allowed is absent" do
      node = %Node{
        children: [%Node{id: "n_Mk3PjLYVpuGI", type: "test/rogue", version: 1}],
        id: "n_QjR9Ni9nMkzO",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{},
        name: "test/example",
        version: 1
      }

      assert validate_admission(node, manifest) == []
    end

    test "admits the children the rule lists" do
      node = %Node{
        children: [
          %Node{id: "n_Mk3PjLYVpuGI", type: "test/example", version: 1}
        ],
        id: "n_QjR9Ni9nMkzO",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{allowed: ["test/example"]},
        name: "test/example",
        version: 1
      }

      assert validate_admission(node, manifest) == []
    end

    test "refuses the pair from the parent, both ids" do
      node = %Node{
        children: [%Node{id: "n_Mk3PjLYVpuGI", type: "test/rogue", version: 1}],
        id: "n_QjR9Ni9nMkzO",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{allowed: ["test/example"]},
        name: "test/example",
        version: 1
      }

      assert validate_admission(node, manifest) ==
               [{:refused_child, "n_QjR9Ni9nMkzO", "n_Mk3PjLYVpuGI"}]
    end

    test "reports refused children in the order the node holds them" do
      node = %Node{
        children: [
          %Node{id: "n_HpprvB0V-4aB", type: "test/rogue", version: 1},
          %Node{id: "n_Cy2VLEr1M6t9", type: "test/rogue", version: 1}
        ],
        id: "n_QjR9Ni9nMkzO",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{allowed: ["test/example"]},
        name: "test/example",
        version: 1
      }

      assert validate_admission(node, manifest) == [
               {:refused_child, "n_QjR9Ni9nMkzO", "n_HpprvB0V-4aB"},
               {:refused_child, "n_QjR9Ni9nMkzO", "n_Cy2VLEr1M6t9"}
             ]
    end
  end

  describe "validate_cardinality/2" do
    import Conformance, only: [validate_cardinality: 2]

    test "admits a count at the ceiling exactly" do
      children =
        for index <- 1..2 do
          %Node{id: "n_iAbEZ44WOnR#{index}", type: "test/example", version: 1}
        end

      node = %Node{
        children: children,
        id: "n_JJv0eKPqx9EU",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{maximum: 2},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(node, manifest) == []
    end

    test "admits a count within the bounds" do
      node = %Node{
        children: [
          %Node{id: "n_iAbEZ44WOnRe", type: "test/example", version: 1}
        ],
        id: "n_JJv0eKPqx9EU",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{maximum: 2, minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(node, manifest) == []
    end

    test "admits any count where no containment is declared" do
      node = %Node{id: "n_JJv0eKPqx9EU", type: "test/example", version: 1}
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_cardinality(node, manifest) == []
    end

    test "never overfills under a nil ceiling" do
      children =
        for index <- 1..40 do
          %Node{id: "n_iAbEZ44WOnR#{index}", type: "test/example", version: 1}
        end

      node = %Node{
        children: children,
        id: "n_JJv0eKPqx9EU",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(node, manifest) == []
    end

    test "reports too few once below the floor" do
      node = %Node{id: "n_JJv0eKPqx9EU", type: "test/example", version: 1}

      manifest = %Manifest{
        containment: %Containment{minimum: 2},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(node, manifest) ==
               [{:too_few_children, "n_JJv0eKPqx9EU"}]
    end

    test "reports too many once, however many stand over" do
      children =
        for index <- 1..5 do
          %Node{id: "n_iAbEZ44WOnR#{index}", type: "test/example", version: 1}
        end

      node = %Node{
        children: children,
        id: "n_JJv0eKPqx9EU",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        containment: %Containment{maximum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(node, manifest) ==
               [{:too_many_children, "n_JJv0eKPqx9EU"}]
    end
  end

  describe "validate_keys/2" do
    import Conformance, only: [validate_keys: 2]

    test "reports each undeclared key in its own rejection" do
      node = %Node{
        attributes: %{"content" => "Hello, world!", "level" => 2},
        id: "n_dRl0z-XcTMv2",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_keys(node, manifest) == [
               {:unknown_attribute, "n_dRl0z-XcTMv2", "content"},
               {:unknown_attribute, "n_dRl0z-XcTMv2", "level"}
             ]
    end

    test "reports nothing for a node holding no attributes" do
      node = %Node{id: "n_dRl0z-XcTMv2", type: "test/example", version: 1}
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_keys(node, manifest) == []
    end

    test "reports nothing where every key is declared" do
      node = %Node{
        attributes: %{"content" => "Hello, world!"},
        id: "n_dRl0z-XcTMv2",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{"content" => %Attribute{role: :content, type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_keys(node, manifest) == []
    end
  end

  describe "validate_requiredness/2" do
    import Conformance, only: [validate_requiredness: 2]

    test "admits a held value" do
      node = %Node{
        attributes: %{"src" => "/logo.svg"},
        id: "n_ovLbFWkleq08",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{required: true, role: :content, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(node, manifest) == []
    end

    test "admits absence where nothing is required" do
      node = %Node{id: "n_ovLbFWkleq08", type: "test/example", version: 1}

      manifest = %Manifest{
        attributes: %{"src" => %Attribute{role: :content, type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(node, manifest) == []
    end

    test "refuses a required absence" do
      node = %Node{id: "n_ovLbFWkleq08", type: "test/example", version: 1}

      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{required: true, role: :content, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(node, manifest) ==
               [{:missing_attribute, "n_ovLbFWkleq08", "src"}]
    end

    test "treats a held nil as held" do
      node = %Node{
        attributes: %{"src" => nil},
        id: "n_ovLbFWkleq08",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{required: true, role: :content, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(node, manifest) == []
    end
  end

  describe "validate_root/2" do
    import Conformance, only: [validate_root: 2]

    test "admits a count within the bounds" do
      document = %Document{
        root: [%Node{id: "n_2-mvE1651xJP", type: "test/example", version: 1}]
      }

      containment = %Containment{maximum: 2, minimum: 1}

      assert validate_root(document, containment) == []
    end

    test "admits every root where allowed is absent" do
      document = %Document{
        root: [%Node{id: "n_TC9brJgOKMzs", type: "test/rogue", version: 1}]
      }

      assert validate_root(document, %Containment{}) == []
    end

    test "admits everything under no rule" do
      assert validate_root(%Document{}, %Containment{}) == []
    end

    test "admits the roots the rule lists" do
      document = %Document{
        root: [%Node{id: "n_TC9brJgOKMzs", type: "test/example", version: 1}]
      }

      containment = %Containment{allowed: ["test/example"]}

      assert validate_root(document, containment) == []
    end

    test "refuses each outsider, sorted by id" do
      document = %Document{
        root: [
          %Node{id: "n_YHXf5UYFI9E9", type: "test/rogue", version: 1},
          %Node{id: "n_TC9brJgOKMzs", type: "test/rogue", version: 1}
        ]
      }

      containment = %Containment{allowed: ["test/example"]}

      assert validate_root(document, containment) == [
               {:refused_root, "n_TC9brJgOKMzs"},
               {:refused_root, "n_YHXf5UYFI9E9"}
             ]
    end

    test "reports nothing for an empty document under an empty rule" do
      assert validate_root(%Document{}, %Containment{allowed: []}) == []
    end

    test "reports overfilled above the ceiling, once" do
      nodes =
        for index <- 1..5 do
          %Node{id: "n_2-mvE1651xJ#{index}", type: "test/example", version: 1}
        end

      document = %Document{root: nodes}
      containment = %Containment{maximum: 1}

      assert validate_root(document, containment) == [:overfilled_root]
    end

    test "reports the count beside the refusals, atom first" do
      document = %Document{
        root: [%Node{id: "n_TC9brJgOKMzs", type: "test/rogue", version: 1}]
      }

      containment = %Containment{allowed: ["test/example"], minimum: 2}

      assert validate_root(document, containment) == [
               :underfilled_root,
               {:refused_root, "n_TC9brJgOKMzs"}
             ]
    end

    test "reports underfilled below the floor" do
      assert validate_root(%Document{}, %Containment{minimum: 1}) ==
               [:underfilled_root]
    end
  end

  describe "validate_values/2" do
    import Conformance, only: [validate_values: 2]

    test "admits a value the type admits" do
      node = %Node{
        attributes: %{"level" => 2},
        id: "n_MdOJ0Cx41C7A",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{"level" => %Attribute{role: :chrome, type: :number}},
        name: "test/example",
        version: 1
      }

      assert validate_values(node, manifest) == []
    end

    test "asks the member, so an enum refuses by membership" do
      node = %Node{
        attributes: %{"tag" => "h9"},
        id: "n_MdOJ0Cx41C7A",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{
          "tag" => %Attribute{role: :chrome, type: {:enum, ["h2", "h3"]}}
        },
        name: "test/example",
        version: 1
      }

      assert validate_values(node, manifest) ==
               [{:bad_attribute_value, "n_MdOJ0Cx41C7A", "tag"}]
    end

    test "judges only what is held, absence being another question" do
      node = %Node{id: "n_MdOJ0Cx41C7A", type: "test/example", version: 1}

      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{required: true, role: :content, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_values(node, manifest) == []
    end

    test "refuses a value the type refuses" do
      node = %Node{
        attributes: %{"level" => "2"},
        id: "n_MdOJ0Cx41C7A",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{"level" => %Attribute{role: :chrome, type: :number}},
        name: "test/example",
        version: 1
      }

      assert validate_values(node, manifest) ==
               [{:bad_attribute_value, "n_MdOJ0Cx41C7A", "level"}]
    end

    test "treats a held nil as the lattice does, admitted everywhere" do
      node = %Node{
        attributes: %{"src" => nil},
        id: "n_MdOJ0Cx41C7A",
        type: "test/example",
        version: 1
      }

      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{required: true, role: :content, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_values(node, manifest) == []
    end
  end
end
