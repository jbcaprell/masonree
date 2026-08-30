defmodule Masonree.Manifest.AttributeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Attribute

  doctest Attribute, import: true

  describe "%Attribute{}" do
    test "enforces a type" do
      message = ~r"must also be given .*: \[:type\]"

      assert_raise ArgumentError, message, fn -> struct!(Attribute, []) end
    end

    test "supplies no default, and is not required" do
      assert Map.from_struct(%Attribute{type: :string}) ==
               %{default: nil, required: false, type: :string}
    end
  end
end
