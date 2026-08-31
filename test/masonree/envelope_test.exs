defmodule Masonree.EnvelopeTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.4.0"

  use ExUnit.Case, async: true

  alias Ecto
  alias Masonree
  alias MasonreeBench

  alias Ecto.Adapters
  alias Ecto.Changeset
  alias Masonree.Document
  alias Masonree.Envelope
  alias Masonree.Node
  alias MasonreeBench.Page
  alias MasonreeBench.Repo

  alias Adapters.SQL

  alias SQL.Sandbox

  doctest Envelope, import: true

  describe "Ecto.Type" do
    setup do
      :ok = Sandbox.checkout(Repo)
    end

    test "casts an envelope into the field through a changeset" do
      body = %{
        "root" => [%{"id" => "n_Rele4j97z9QL", "type" => "core/paragraph"}]
      }

      %Page{}
      |> Changeset.cast(%{"body" => body}, [:body])
      |> Repo.insert!()

      assert Repo.one!(Page).body == %Document{
               root: [
                 %Node{id: "n_Rele4j97z9QL", type: "core/paragraph", version: 1}
               ]
             }
    end

    test "queries the stored tree as jsonb, not as bytes" do
      body = %Document{
        root: [
          %Node{
            attributes: %{"content" => "Hello, world!"},
            id: "n_mBdBEWyfcCEl",
            type: "core/paragraph",
            version: 1
          }
        ]
      }

      Repo.insert!(%Page{body: body})

      query =
        """
        SELECT body #>> '{root,0,type}', body #>> '{root,0,attributes,content}'
          FROM page
        """

      assert %{rows: [["core/paragraph", "Hello, world!"]]} =
               SQL.query!(Repo, query, [])
    end

    test "raises at the query on a row the reader refuses" do
      query = "INSERT INTO page (body) VALUES ($1)"
      body = %{"root" => [%{"id" => "n_l1OGa7AgrSGz"}]}
      message = ~r"cannot load .* as type Masonree.Envelope"

      assert %{num_rows: 1} = SQL.query!(Repo, query, [body])

      assert_raise ArgumentError, message, fn -> Repo.one!(Page) end
    end

    test "refuses through a changeset what the reader refuses" do
      body = %{"root" => [%{"id" => "n_3O6WZwhROF8v"}]}

      changeset = Changeset.cast(%Page{}, %{"body" => body}, [:body])

      refute changeset.valid?

      assert changeset.errors ==
               [body: {"is invalid", [type: Envelope, validation: :cast]}]
    end

    test "stores an empty document as a row, not an absence" do
      Repo.insert!(%Page{body: %Document{}})

      assert Repo.one!(Page).body == %Document{}
    end

    test "survives a real insert and a real read" do
      body = %Document{
        root: [
          %Node{
            attributes: %{"width" => "wide"},
            children: [
              %Node{
                attributes: %{"content" => "Stored"},
                id: "n_1In7_0UAvWz5",
                preset: "loud",
                type: "core/paragraph",
                version: 1
              }
            ],
            id: "n_8QYwiz-CFK_L",
            type: "test/example",
            version: 1
          }
        ]
      }

      Repo.insert!(%Page{body: body})

      assert Repo.one!(Page).body == body
    end
  end

  describe "Envelope" do
    test "declares itself an Ecto.Type, so a schema may name it as a field" do
      attributes = Envelope.__info__(:attributes)

      assert attributes[:behaviour] == [Ecto.Type]
    end
  end

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
