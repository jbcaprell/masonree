defmodule Masonree.EnvelopeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Envelope

  doctest Envelope, import: true

  describe "type/0" do
    import Envelope, only: [type: 0]

    test "is :map, so the column is jsonb and not text" do
      assert type() == :map
    end
  end
end
