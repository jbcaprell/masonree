defmodule Masonree.ManifestTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute
  alias Manifest.Containment
  alias Manifest.Template

  doctest Manifest, import: true

  describe "%Manifest{}" do
    test "carries a containment where the block declares one" do
      containment = %Containment{minimum: 1}

      manifest = %Manifest{
        containment: containment,
        name: "test/example",
        version: 1
      }

      assert manifest.containment == containment
    end

    test "carries a declared attribute" do
      attribute = %Attribute{default: "", type: :string}

      manifest = %Manifest{
        attributes: %{"content" => attribute},
        name: "test/example",
        version: 1
      }

      assert manifest.attributes["content"] == attribute
    end

    test "defaults to no attributes, category, containment or label" do
      assert Map.from_struct(%Manifest{name: "test/example", version: 1}) == %{
               attributes: %{},
               category: nil,
               containment: nil,
               label: nil,
               name: "test/example",
               version: 1
             }
    end

    test "enforces a name and a version" do
      message = ~r"must also be given .*: \[:name, :version\]"

      assert_raise ArgumentError, message, fn -> struct!(Manifest, []) end
    end
  end

  describe "get_namespace/1" do
    import Manifest, only: [get_namespace: 1]

    test "answers nil for a name with no separator to split" do
      assert get_namespace("example") == nil
    end

    test "answers nil when a second separator makes the name ambiguous" do
      assert get_namespace("test/example/extra") == nil
    end

    test "answers nil when either half of the name is empty" do
      assert get_namespace("/example") == nil
      assert get_namespace("test/") == nil
    end

    test "takes the owning half of a namespaced name" do
      assert get_namespace("core/paragraph") == "core"
    end
  end

  describe "unstartable?/1" do
    import Manifest, only: [unstartable?: 1]

    test "answers false where a template is offered" do
      manifest = %Manifest{
        containment: %Containment{
          minimum: 1,
          templates: [%Template{label: "Template", type: "test/example"}]
        },
        name: "test/example",
        version: 1
      }

      refute unstartable?(manifest)
    end

    test "answers false where no containment is declared" do
      refute unstartable?(%Manifest{name: "test/example", version: 1})
    end

    test "answers false where the floor is zero" do
      manifest = %Manifest{
        containment: %Containment{minimum: 0},
        name: "test/example",
        version: 1
      }

      refute unstartable?(manifest)
    end

    test "answers true where a floor stands and no template is offered" do
      manifest = %Manifest{
        containment: %Containment{minimum: 2},
        name: "test/example",
        version: 1
      }

      assert unstartable?(manifest)
    end
  end

  describe "validate/1" do
    import Manifest, only: [validate: 1]

    test "answers an empty report for a well-formed manifest" do
      manifest = %Manifest{
        attributes: %{
          "content" => %Attribute{default: "", role: :content, type: :string},
          "tag" => %Attribute{
            default: "h2",
            role: :chrome,
            type: {:enum, ["h2", "h3"]}
          }
        },
        name: "test/example",
        version: 1
      }

      assert validate(manifest) == []
    end

    test "reports an ill-keyed manifest’s key as it was found" do
      manifest = %Manifest{
        attributes: %{content: %Attribute{role: :content, type: :bool}},
        name: "test/example",
        version: 1
      }

      assert validate(manifest) == [
               {:non_string_keys, "test/example"},
               {:bad_attribute_type, "test/example", :content}
             ]
    end

    test "reports every fault in one pass, not the first it meets" do
      manifest = %Manifest{
        attributes: %{
          "content" => %Attribute{role: :content, type: :bool},
          "src" => %Attribute{
            default: "",
            required: true,
            role: :content,
            type: :string
          }
        },
        name: "example",
        version: 1
      }

      assert validate(manifest) == [
               {:unnamespaced_name, "example"},
               {:bad_attribute_type, "example", "content"},
               {:required_with_default, "example", "src"}
             ]
    end

    test "reports one fault once, as what it is" do
      manifest = %Manifest{
        attributes: %{
          "rank" => %Attribute{default: "2", role: :chrome, type: :bool}
        },
        name: "test/example",
        version: 1
      }

      assert validate(manifest) ==
               [{:bad_attribute_type, "test/example", "rank"}]
    end

    test "sorts the same report above the flat map’s 32-key boundary" do
      declare = fn index ->
        {
          "key-#{index}",
          %Attribute{default: index, role: :chrome, type: :string}
        }
      end

      manifest = %Manifest{
        attributes: Map.new(1..40, declare),
        name: "test/example",
        version: 1
      }

      report = validate(manifest)

      assert length(report) == 40
      assert report == Enum.sort(report)
    end
  end

  describe "validate_cardinality/1" do
    import Manifest, only: [validate_cardinality: 1]

    test "admits a floor with no ceiling" do
      manifest = %Manifest{
        containment: %Containment{minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(manifest) == []
    end

    test "admits bounds a page can satisfy" do
      manifest = %Manifest{
        containment: %Containment{maximum: 3, minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(manifest) == []
    end

    test "judges nothing where no containment is declared" do
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_cardinality(manifest) == []
    end

    test "refuses a bound that is not an integer" do
      manifest = %Manifest{
        containment: %Containment{maximum: "3", minimum: 1.5},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(manifest) ==
               [{:bad_cardinality, "test/example"}]
    end

    test "refuses a ceiling below the floor" do
      manifest = %Manifest{
        containment: %Containment{maximum: 1, minimum: 2},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(manifest) ==
               [{:bad_cardinality, "test/example"}]
    end

    test "refuses a floor below zero" do
      manifest = %Manifest{
        containment: %Containment{minimum: -1},
        name: "test/example",
        version: 1
      }

      assert validate_cardinality(manifest) ==
               [{:bad_cardinality, "test/example"}]
    end
  end

  describe "validate_defaults/1" do
    import Manifest, only: [validate_defaults: 1]

    test "admits a default the enum holds" do
      manifest = %Manifest{
        attributes: %{
          "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
        },
        name: "test/example",
        version: 1
      }

      assert validate_defaults(manifest) == []
    end

    test "leaves a payload that is not a list to its own rejection" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{default: "h2", type: {:enum, nil}}},
        name: "test/example",
        version: 1
      }

      assert validate_defaults(manifest) == []
    end

    test "leaves a scalar’s default to the type rule" do
      manifest = %Manifest{
        attributes: %{"rank" => %Attribute{default: "2", type: :number}},
        name: "test/example",
        version: 1
      }

      assert validate_defaults(manifest) == []
    end

    test "refuses a default the enum does not hold" do
      manifest = %Manifest{
        attributes: %{
          "tag" => %Attribute{default: "h9", type: {:enum, ["h2", "h3"]}}
        },
        name: "test/example",
        version: 1
      }

      assert validate_defaults(manifest) ==
               [{:default_outside_enum, "test/example", "tag"}]
    end

    test "treats a nil default as absence, whatever the values" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, ["h2", "h3"]}}},
        name: "test/example",
        version: 1
      }

      assert validate_defaults(manifest) == []
    end
  end

  describe "validate_duplicates/1" do
    import Manifest, only: [validate_duplicates: 1]

    test "admits an enum whose values repeat nothing" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, ["h2", "h3"]}}},
        name: "test/example",
        version: 1
      }

      assert validate_duplicates(manifest) == []
    end

    test "counts strictly, so a float never repeats an integer" do
      manifest = %Manifest{
        attributes: %{"rank" => %Attribute{type: {:enum, [1, 1.0]}}},
        name: "test/example",
        version: 1
      }

      assert validate_duplicates(manifest) == []
    end

    test "leaves a payload that is not a list to its own rejection" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, "h2"}}},
        name: "test/example",
        version: 1
      }

      assert validate_duplicates(manifest) == []
    end

    test "refuses a repeated value however far apart the copies sit" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, ["h2", "h3", "h2"]}}},
        name: "test/example",
        version: 1
      }

      assert validate_duplicates(manifest) ==
               [{:duplicate_enum_values, "test/example", "tag"}]
    end
  end

  describe "validate_enums/1" do
    import Manifest, only: [validate_enums: 1]

    test "admits an enum that offers at least one value" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, ["h2"]}}},
        name: "test/example",
        version: 1
      }

      assert validate_enums(manifest) == []
    end

    test "leaves a payload that is not a list to its own rejection" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, nil}}},
        name: "test/example",
        version: 1
      }

      assert validate_enums(manifest) == []
    end

    test "refuses an enum with no values to admit" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, []}}},
        name: "test/example",
        version: 1
      }

      assert validate_enums(manifest) == [{:empty_enum, "test/example", "tag"}]
    end
  end

  describe "validate_fillability/1" do
    import Manifest, only: [validate_fillability: 1]

    test "admits a floor an allowed list can meet" do
      manifest = %Manifest{
        containment: %Containment{allowed: ["test/example"], minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_fillability(manifest) == []
    end

    test "admits a floor under no allowed list at all" do
      manifest = %Manifest{
        containment: %Containment{minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_fillability(manifest) == []
    end

    test "admits an interior sealed on purpose" do
      manifest = %Manifest{
        containment: %Containment{allowed: [], minimum: 0},
        name: "test/example",
        version: 1
      }

      assert validate_fillability(manifest) == []
    end

    test "judges nothing where no containment is declared" do
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_fillability(manifest) == []
    end

    test "refuses a floor above an interior admitting nothing" do
      manifest = %Manifest{
        containment: %Containment{allowed: [], minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_fillability(manifest) ==
               [{:unfillable_interior, "test/example"}]
    end
  end

  describe "validate_format/1" do
    import Manifest, only: [validate_format: 1]

    test "admits every casing style, because shape is not style" do
      manifest = %Manifest{
        attributes: %{
          "TagName" => %Attribute{type: :string},
          "dotted.name" => %Attribute{type: :string},
          "kebab-case" => %Attribute{type: :string},
          "snake_case" => %Attribute{type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) == []
    end

    test "leaves a key that is not a string to its own rejection" do
      manifest = %Manifest{
        attributes: %{1 => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) == []
    end

    test "names every offending key, not the first it meets" do
      manifest = %Manifest{
        attributes: %{
          "" => %Attribute{type: :string},
          "tag name" => %Attribute{type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) == [
               {:bad_key_format, "test/example", ""},
               {:bad_key_format, "test/example", "tag name"}
             ]
    end

    test "refuses a control character wherever it hides" do
      manifest = %Manifest{
        attributes: %{"tag\0name" => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) ==
               [{:bad_key_format, "test/example", "tag\0name"}]
    end

    test "refuses a non-breaking space, which a reader cannot see" do
      manifest = %Manifest{
        attributes: %{"tag\u00A0name" => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) ==
               [{:bad_key_format, "test/example", "tag\u00A0name"}]
    end

    test "refuses a trailing newline, which prints as the key it is not" do
      manifest = %Manifest{
        attributes: %{"content\n" => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_format(manifest) ==
               [{:bad_key_format, "test/example", "content\n"}]
    end
  end

  describe "validate_keys/1" do
    import Manifest, only: [validate_keys: 1]

    test "admits a manifest whose keys are all strings" do
      manifest = %Manifest{
        attributes: %{"content" => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_keys(manifest) == []
    end

    test "refuses an integer key the same as an atom one" do
      manifest = %Manifest{
        attributes: %{1 => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_keys(manifest) == [{:non_string_keys, "test/example"}]
    end

    test "reports once however many keys offend" do
      manifest = %Manifest{
        attributes: %{
          :content => %Attribute{type: :string},
          :tag => %Attribute{type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_keys(manifest) == [{:non_string_keys, "test/example"}]
    end
  end

  describe "validate_name/1" do
    import Manifest, only: [validate_name: 1]

    test "admits lowercase letters, digits and hyphens in either half" do
      assert validate_name(%Manifest{name: "test-1/example-2", version: 1}) ==
               []
    end

    test "refuses a doubled separator, which hides an empty half" do
      assert validate_name(%Manifest{name: "test//example", version: 1}) ==
               [{:unnamespaced_name, "test//example"}]
    end

    test "refuses a name that carries no namespace at all" do
      assert validate_name(%Manifest{name: "example", version: 1}) ==
               [{:unnamespaced_name, "example"}]
    end

    test "refuses a trailing newline, which prints as the name it is not" do
      assert validate_name(%Manifest{name: "test/example\n", version: 1}) ==
               [{:unnamespaced_name, "test/example\n"}]
    end

    test "refuses an uppercase letter, so a namespace has one spelling" do
      assert validate_name(%Manifest{name: "Test/example", version: 1}) ==
               [{:unnamespaced_name, "Test/example"}]
    end

    test "refuses whitespace anywhere in the name" do
      assert validate_name(%Manifest{name: " /example", version: 1}) ==
               [{:unnamespaced_name, " /example"}]

      assert validate_name(%Manifest{name: "test/exa mple", version: 1}) ==
               [{:unnamespaced_name, "test/exa mple"}]
    end
  end

  describe "validate_requiredness/1" do
    import Manifest, only: [validate_requiredness: 1]

    test "admits a default alone, filled where a value is absent" do
      manifest = %Manifest{
        attributes: %{"text" => %Attribute{default: "", type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(manifest) == []
    end

    test "admits requiredness alone, which is what it is for" do
      manifest = %Manifest{
        attributes: %{"src" => %Attribute{required: true, type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(manifest) == []
    end

    test "refuses the pair, whose halves cancel" do
      manifest = %Manifest{
        attributes: %{
          "src" => %Attribute{default: "", required: true, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_requiredness(manifest) ==
               [{:required_with_default, "test/example", "src"}]
    end
  end

  describe "validate_roles/1" do
    import Manifest, only: [validate_roles: 1]

    test "admits either side of the pair" do
      manifest = %Manifest{
        attributes: %{
          "content" => %Attribute{role: :content, type: :string},
          "width" => %Attribute{role: :chrome, type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_roles(manifest) == []
    end

    test "refuses a role outside the pair, misspelled or minted" do
      manifest = %Manifest{
        attributes: %{"width" => %Attribute{role: :style, type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_roles(manifest) ==
               [{:undeclared_role, "test/example", "width"}]
    end

    test "refuses an undeclared role, which is a side not chosen" do
      manifest = %Manifest{
        attributes: %{"content" => %Attribute{type: :string}},
        name: "test/example",
        version: 1
      }

      assert validate_roles(manifest) ==
               [{:undeclared_role, "test/example", "content"}]
    end
  end

  describe "validate_scalars/1" do
    import Manifest, only: [validate_scalars: 1]

    test "admits a default its own type admits" do
      manifest = %Manifest{
        attributes: %{
          "flag" => %Attribute{default: false, type: :boolean},
          "text" => %Attribute{default: "", type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_scalars(manifest) == []
    end

    test "judges no default against a type that does not exist" do
      manifest = %Manifest{
        attributes: %{"rank" => %Attribute{default: "true", type: :bool}},
        name: "test/example",
        version: 1
      }

      assert validate_scalars(manifest) == []
    end

    test "leaves an enum’s default to the membership rule" do
      manifest = %Manifest{
        attributes: %{
          "tag" => %Attribute{default: "h9", type: {:enum, ["h2", "h3"]}}
        },
        name: "test/example",
        version: 1
      }

      assert validate_scalars(manifest) == []
    end

    test "refuses a default its own type refuses" do
      manifest = %Manifest{
        attributes: %{"rank" => %Attribute{default: "2", type: :number}},
        name: "test/example",
        version: 1
      }

      assert validate_scalars(manifest) ==
               [{:default_type_mismatch, "test/example", "rank"}]
    end

    test "treats a nil default as absence, never as a wrong value" do
      manifest = %Manifest{
        attributes: %{"rank" => %Attribute{type: :number}},
        name: "test/example",
        version: 1
      }

      assert validate_scalars(manifest) == []
    end
  end

  describe "validate_startability/1" do
    import Manifest, only: [validate_startability: 1]

    test "admits an interior a template starts" do
      manifest = %Manifest{
        containment: %Containment{
          minimum: 1,
          templates: [%Template{label: "Template", type: "test/example"}]
        },
        name: "test/example",
        version: 1
      }

      assert validate_startability(manifest) == []
    end

    test "judges nothing where no containment is declared" do
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_startability(manifest) == []
    end

    test "refuses the interior no editor can start" do
      manifest = %Manifest{
        containment: %Containment{minimum: 1},
        name: "test/example",
        version: 1
      }

      assert validate_startability(manifest) ==
               [{:unstartable_interior, "test/example"}]
    end
  end

  describe "validate_templates/1" do
    import Manifest, only: [validate_templates: 1]

    test "admits templates of the offered shape, at any depth" do
      manifest = %Manifest{
        containment: %Containment{
          templates: [
            %Template{
              children: [%Template{label: "Child", type: "test/other"}],
              label: "Template",
              type: "test/example"
            }
          ]
        },
        name: "test/example",
        version: 1
      }

      assert validate_templates(manifest) == []
    end

    test "judges nothing where no containment is declared" do
      manifest = %Manifest{name: "test/example", version: 1}

      assert validate_templates(manifest) == []
    end

    test "refuses a child template whose type is not a string" do
      manifest = %Manifest{
        containment: %Containment{
          templates: [
            %Template{
              children: [%Template{label: "Child", type: :example}],
              label: "Template",
              type: "test/example"
            }
          ]
        },
        name: "test/example",
        version: 1
      }

      assert validate_templates(manifest) ==
               [{:malformed_template, "test/example"}]
    end

    test "refuses a root template whose type is not a string" do
      manifest = %Manifest{
        containment: %Containment{
          templates: [%Template{label: "Template", type: :example}]
        },
        name: "test/example",
        version: 1
      }

      assert validate_templates(manifest) ==
               [{:malformed_template, "test/example"}]
    end
  end

  describe "validate_types/1" do
    import Manifest, only: [validate_types: 1]

    test "admits every type the lattice holds" do
      manifest = %Manifest{
        attributes: %{
          "flag" => %Attribute{type: :boolean},
          "rank" => %Attribute{type: :number},
          "tag" => %Attribute{type: {:enum, ["h2", "h3"]}},
          "text" => %Attribute{type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_types(manifest) == []
    end

    test "leaves what a payload contains to the declaration’s own rules" do
      manifest = %Manifest{
        attributes: %{"tag" => %Attribute{type: {:enum, []}}},
        name: "test/example",
        version: 1
      }

      assert validate_types(manifest) == []
    end

    test "refuses a payload on a scalar, naming the attribute that errs" do
      manifest = %Manifest{
        attributes: %{"text" => %Attribute{type: {:string, []}}},
        name: "test/example",
        version: 1
      }

      assert validate_types(manifest) ==
               [{:bad_attribute_type, "test/example", "text"}]
    end

    test "refuses a type outside the lattice, wherever it is declared" do
      manifest = %Manifest{
        attributes: %{
          "one" => %Attribute{type: :bool},
          "two" => %Attribute{type: :string}
        },
        name: "test/example",
        version: 1
      }

      assert validate_types(manifest) ==
               [{:bad_attribute_type, "test/example", "one"}]
    end
  end

  describe "validate_version/1" do
    import Manifest, only: [validate_version: 1]

    test "admits any count of migrations a block has actually taken" do
      assert validate_version(%Manifest{name: "test/example", version: 7}) ==
               []
    end

    test "refuses a float, even one that prints as a whole number" do
      assert validate_version(%Manifest{name: "test/example", version: 1.0}) ==
               [{:bad_version, "test/example"}]
    end

    test "refuses zero and below, where the count begins at one" do
      assert validate_version(%Manifest{name: "test/example", version: 0}) ==
               [{:bad_version, "test/example"}]

      assert validate_version(%Manifest{name: "test/example", version: -1}) ==
               [{:bad_version, "test/example"}]
    end
  end
end
