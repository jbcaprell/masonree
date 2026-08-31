defmodule Masonree.EnvelopeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Document
  alias Masonree.Envelope
  alias Masonree.Node

  doctest Envelope, import: true

  describe "cast/1" do
    import Envelope, only: [cast: 1]

    test "passes a document through untouched" do
      document = %Document{
        root: [%Node{id: "n_MHnhDZRkFLiN", type: "core/paragraph", version: 1}]
      }

      assert cast(document) == {:ok, document}
    end

    test "reads an envelope" do
      envelope = %{
        "root" => [%{"id" => "n_1VRRqhnB3XSq", "type" => "core/paragraph"}]
      }

      assert cast(envelope) == {
               :ok,
               %Document{
                 root: [
                   %Node{
                     id: "n_1VRRqhnB3XSq",
                     type: "core/paragraph",
                     version: 1
                   }
                 ]
               }
             }
    end

    test "refuses a keyword list, which is not an envelope" do
      assert cast(root: []) == :error
    end

    test "refuses a struct that is not a document" do
      node = %Node{id: "n_WEYp4sgKpRpp", type: "test/example", version: 1}

      assert cast(node) == :error
    end

    test "refuses an envelope the reader refuses" do
      assert cast(%{"root" => [%{"children" => [%{}]}]}) == :error
    end
  end

  describe "dump/1" do
    import Envelope, only: [dump: 1]

    test "refuses a document the reader could not read back" do
      document = %Document{
        root: [%Node{id: "n_s6q4_6igRknZ", type: 1, version: 1}]
      }

      assert dump(document) == :error
    end

    test "refuses an envelope, which is not a document" do
      assert dump(%{"root" => []}) == :error
    end

    test "writes a nested document whole" do
      document = %Document{
        root: [
          %Node{
            children: [
              %Node{id: "n_WVOxvPhRssoM", type: "core/paragraph", version: 1}
            ],
            id: "n_Pq-SqHcw9dq-",
            type: "test/example",
            version: 1
          }
        ]
      }

      assert dump(document) == {
               :ok,
               %{
                 "root" => [
                   %{
                     "attributes" => %{},
                     "children" => [
                       %{
                         "attributes" => %{},
                         "children" => [],
                         "id" => "n_WVOxvPhRssoM",
                         "preset" => nil,
                         "type" => "core/paragraph",
                         "version" => 1
                       }
                     ],
                     "id" => "n_Pq-SqHcw9dq-",
                     "preset" => nil,
                     "type" => "test/example",
                     "version" => 1
                   }
                 ]
               }
             }
    end
  end

  describe "load/1" do
    import Envelope, only: [load: 1]

    test "fills every absence the envelope carries" do
      assert {:ok, document} = load(%{"root" => [%{"type" => "test/example"}]})
      assert [node] = document.root

      assert {node.attributes, node.children, node.preset, node.version} ==
               {%{}, [], nil, 1}

      assert String.starts_with?(node.id, "n_")
    end

    test "reads a missing root as an empty document" do
      assert load(%{}) == {:ok, %Document{root: []}}
    end

    test "refuses a list, which is not an envelope" do
      assert load([]) == :error
    end

    test "refuses an unreadable envelope with an error, never a raise" do
      assert load(%{"root" => [%{}]}) == :error
    end
  end

  describe "type/0" do
    import Envelope, only: [type: 0]

    test "is :map, so the column is jsonb and not text" do
      assert type() == :map
    end
  end
end
