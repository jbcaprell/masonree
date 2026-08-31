defmodule MasonreeBench.PageTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias Masonree
  alias MasonreeBench

  alias Masonree.Envelope
  alias MasonreeBench.Page

  describe "MasonreeBench.Page" do
    test "carries one field and no key, so a row has no identity to thread" do
      assert Page.__schema__(:fields) == [:body]
      assert Page.__schema__(:primary_key) == []
    end

    test "names the table the suite will have to create it under" do
      assert Page.__schema__(:source) == "page"
    end

    test "types the body as the library’s own Ecto type, not as a map" do
      assert Page.__schema__(:type, :body) == Envelope
    end
  end
end
