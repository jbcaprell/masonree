defmodule Masonree.Manifest.TemplateTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.6.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute
  alias Manifest.Template

  doctest Template, import: true

  describe "%Template{}" do
    test "enforces a label and a type" do
      message = ~r"must also be given .*: \[:label, :type\]"

      assert_raise ArgumentError, message, fn -> struct!(Template, []) end
    end

    test "keeps its children in the order they are given" do
      template = %Template{
        children: [
          %Template{label: "First", type: "test/example"},
          %Template{label: "Second", type: "test/example"}
        ],
        label: "Template",
        type: "test/example"
      }

      assert Enum.map(template.children, & &1.label) == ["First", "Second"]
    end

    test "starts with no attributes and no children" do
      template = %Template{label: "Template", type: "test/example"}

      assert Map.from_struct(template) == %{
               attributes: %{},
               children: [],
               label: "Template",
               type: "test/example"
             }
    end
  end

  describe "stamp/2" do
    import Template, only: [stamp: 2]

    test "applies the declared defaults each entry leaves absent" do
      template = %Template{label: "Template", type: "test/example"}

      manifests = %{
        "test/example" => %Manifest{
          attributes: %{
            "content" => %Attribute{default: "", role: :content, type: :string}
          },
          name: "test/example",
          version: 1
        }
      }

      node = stamp(template, manifests)

      assert node.attributes == %{"content" => ""}
    end

    test "mints fresh ids at every stamping" do
      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      template = %Template{label: "Template", type: "test/example"}

      refute stamp(template, manifests).id == stamp(template, manifests).id
    end

    test "raises on a type the manifests do not name" do
      template = %Template{label: "Template", type: "test/absent"}

      assert_raise KeyError, fn -> stamp(template, %{}) end
    end

    test "stamps the interior whole, in the order the template gives" do
      manifests = %{
        "test/example" => %Manifest{name: "test/example", version: 1}
      }

      template = %Template{
        children: [
          %Template{
            attributes: %{"content" => "First"},
            label: "First",
            type: "test/example"
          },
          %Template{
            attributes: %{"content" => "Second"},
            label: "Second",
            type: "test/example"
          }
        ],
        label: "Template",
        type: "test/example"
      }

      node = stamp(template, manifests)

      assert Enum.map(node.children, & &1.attributes["content"]) ==
               ["First", "Second"]
    end
  end
end
