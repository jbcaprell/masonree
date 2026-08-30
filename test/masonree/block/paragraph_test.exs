defmodule Masonree.Block.ParagraphTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Block
  alias Masonree.Manifest

  alias Manifest.Attribute

  describe "manifest/0" do
    import Block.Paragraph, only: [manifest: 0]

    test "returns the declaration whole" do
      assert manifest() == %Manifest{
               attributes: %{
                 "content" => %Attribute{default: "", type: :string}
               },
               category: "text",
               label: "Paragraph",
               name: "core/paragraph",
               version: 1
             }
    end
  end
end
