defmodule Masonree.Manifest.TemplateTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.6.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

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
end
