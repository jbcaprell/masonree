defmodule Masonree.Conformance do
  @moduledoc """
  Defines conformance reporting over a document.

  This module reports and never raises on content. A stored page outlives the
  blocks that made it — a deactivated block leaves its nodes behind — and a page
  that could not be loaded because one block is gone would make every
  deactivation a data loss. So an unknown block is a report, a malformed
  attribute value is a report, and the page survives every one of them. Raising
  is the read boundary’s posture about malformed envelopes, and it stops there.

  A report changes nothing. Repairing what a report finds is another module’s
  work, and one function that both judged and healed would carry two postures
  with no way to ask for either alone. When to check is the caller’s: on drop,
  on save, on publish — this module only answers.

  The manifests are consulted as a plain map from block name to manifest, a
  shape any caller can build from whatever holds its blocks. Each class of
  problem is one function over a node and the manifest that declares its
  block, as each class of malformed declaration is one function over a manifest
  in `Masonree.Manifest`.

  Whether a type may hold a value is not answered here: the member answers,
  through `Masonree.Type.admits?/2`, and this module never learns what a type
  is. Problems carry the node’s id and whatever the document cannot already
  supply — the id finds the node, the node knows its type, so an unknown block
  needs no second element where an attribute problem names its key.
  """
  @moduledoc since: "0.7.0"
end
