defmodule Masonree.ManifestTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  doctest Manifest, import: true

  describe "%Manifest{}" do
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
end
