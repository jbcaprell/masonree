defmodule Masonree.Reconciliation do
  @moduledoc """
  Defines the repair a document takes on its way to storage.

  This module changes a document and reports what it could not change.
  `Masonree.Conformance` is its opposite posture — reports and changes nothing —
  and the two never share a function: a caller asks to be told, or asks to be
  repaired, and a function that did both could not be asked for either alone.

  Everything removed is reported. A key taken out silently is a key nothing can
  get back — the healed document no longer holds it, so the report is the only
  record it was ever there — and discarding what it does not recognise, quietly,
  is how a repair turns a valid page into a lesser one.

  What a value may be is the lattice’s to answer, through
  `Masonree.Type.admits?/2` and `Masonree.Type.heal/3`; what a page may hold is
  the manifests’; and what the database can represent is this module’s own first
  question, because `jsonb` restrings some shapes and refuses one, and the write
  boundary is the last place to say so before it happens.
  """
  @moduledoc since: "0.8.0"

  alias Masonree

  alias Masonree.Type

  @typedoc "Represents anything a node’s attribute map can hold, key or value."
  @typedoc since: "0.8.0"
  @type value() :: Type.value()

  @doc """
  Returns whether the database can hold `value` exactly as it stands.

  Attributes are stored as `jsonb`, and three shapes survive every in-memory
  witness and then quietly become different data at the first write: an
  integer map key becomes a string, an atom key becomes a string, and an atom
  value becomes a string. A fourth shape does not restring, it refuses — a
  string carrying a NUL byte, because `jsonb` is `text` underneath and
  PostgreSQL has no representation for a NUL in `text`. Every other byte a
  binary can hold is fine — a tab, a newline, invalid UTF-8 — and only the NUL
  fails the write outright.

  The test is the round trip itself, so `nil`, booleans, numbers, NUL-free
  strings, lists of representable values and string-keyed maps of them all pass
  — and the question recurses, because a divergent shape three levels down
  restrings just as quietly.

  ## Example

      iex> representable?(<<0>>)
      false

  """
  @doc since: "0.8.0"
  @spec representable?(value()) :: boolean()
  def representable?(nil), do: true
  def representable?(value) when is_boolean(value), do: true
  def representable?(value) when is_number(value), do: true

  def representable?(value) when is_binary(value) do
    not String.contains?(value, <<0>>)
  end

  def representable?(value) when is_list(value) do
    Enum.all?(value, &representable?/1)
  end

  def representable?(value) when is_map(value) do
    representable_entry? = fn {key, nested} ->
      is_binary(key) and representable?(nested)
    end

    Enum.all?(value, representable_entry?)
  end

  def representable?(_value), do: false
end
