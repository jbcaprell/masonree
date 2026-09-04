defmodule Masonree.ConformanceTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.7.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Conformance
  alias Masonree.Manifest
  alias Masonree.Node

  alias Manifest.Attribute

  doctest Conformance, import: true

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
