defmodule Masonree.ManifestTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute

  doctest Manifest, import: true

  describe "%Manifest{}" do
    test "carries a declared attribute" do
      attribute = %Attribute{default: "", type: :string}

      manifest = %Manifest{
        attributes: %{"content" => attribute},
        name: "test/example",
        version: 1
      }

      assert manifest.attributes["content"] == attribute
    end

    test "defaults to no attributes, category or label" do
      assert Map.from_struct(%Manifest{name: "test/example", version: 1}) == %{
               attributes: %{},
               category: nil,
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
