defmodule MasonreeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.1.0"

  use ExUnit.Case, async: true

  alias Masonree

  doctest Masonree, import: true

  describe "Masonree" do
    test "the boundary defines no functions or macros" do
      assert Masonree.__info__(:functions) == []
      assert Masonree.__info__(:macros) == []
    end
  end
end
