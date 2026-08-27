defmodule MasonreeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.1.0"

  use ExUnit.Case, async: true

  alias Masonree

  doctest Masonree, import: true

  describe "greet/0" do
    import Masonree, only: [greet: 0]

    test "returns the greeting" do
      assert greet() == "Hello, world!"
    end
  end
end
