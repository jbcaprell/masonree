defmodule Masonree.Manifest.ContainmentTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.6.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Containment
  alias Manifest.Template

  doctest Containment, import: true

  describe "%Containment{}" do
    test "declares nothing by default" do
      assert Map.from_struct(%Containment{}) ==
               %{allowed: nil, maximum: nil, minimum: 0, templates: []}
    end

    test "keeps its templates in the order they are given" do
      containment = %Containment{
        templates: [
          %Template{label: "First", type: "test/example"},
          %Template{label: "Second", type: "test/example"}
        ]
      }

      assert Enum.map(containment.templates, & &1.label) == ["First", "Second"]
    end

    test "tells an absent rule from an empty one" do
      assert %Containment{}.allowed == nil
      assert %Containment{allowed: []}.allowed == []
    end
  end
end
