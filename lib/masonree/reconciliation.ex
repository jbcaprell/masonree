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
end
