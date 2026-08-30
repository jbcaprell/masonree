defmodule Masonree.DocumentTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Document
  alias Masonree.Node

  doctest Document, import: true

  describe "%Document{}" do
    test "is an empty root and nothing else" do
      assert Map.from_struct(%Document{}) == %{root: []}
    end
  end
end
