defmodule MasonreeBenchTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias MasonreeBench

  doctest MasonreeBench, import: true

  describe "MasonreeBench" do
    test "declares a boundary of its own, not a corner of the library’s" do
      attributes = MasonreeBench.__info__(:attributes)

      assert Keyword.has_key?(attributes, Boundary)
    end

    test "the boundary defines no functions or macros" do
      assert MasonreeBench.__info__(:functions) == []
      assert MasonreeBench.__info__(:macros) == []
    end
  end
end
