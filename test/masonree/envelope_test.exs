defmodule Masonree.EnvelopeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Document
  alias Masonree.Envelope
  alias Masonree.Node

  doctest Envelope, import: true

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

  describe "type/0" do
    import Envelope, only: [type: 0]

    test "is :map, so the column is jsonb and not text" do
      assert type() == :map
    end
  end
end
