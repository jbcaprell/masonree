defmodule Masonree.Type.BooleanTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Type

  doctest Type.Boolean, import: true

  describe "admits?/2" do
    import Type.Boolean, only: [admits?: 2]

    test "takes a flag, and never its spelling" do
      assert admits?(nil, true)
      assert admits?(nil, false)
      refute admits?(nil, "true")
      refute admits?(nil, 1)
    end
  end
end
