defmodule Masonree.ProjectionTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Projection

  doctest Projection, import: true

  describe "renderable?/1" do
    import Projection, only: [renderable?: 1]

    defmodule Silent do
      use Masonree.Block

      @manifest %Manifest{name: "test/silent", version: 1}
    end

    test "answers false for a manifest-only block, which is legal" do
      refute renderable?(Silent)
    end

    test "answers true for a block with markup" do
      assert renderable?(Block.Paragraph)
    end
  end
end
