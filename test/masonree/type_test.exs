defmodule Masonree.TypeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type, import: true

  describe "Type" do
    test "the lattice asks one question, and every member must answer" do
      assert Type.behaviour_info(:callbacks) == [admits?: 2]
      assert Type.behaviour_info(:optional_callbacks) == []
    end
  end
end
