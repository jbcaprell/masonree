defmodule Masonree.Manifest.Containment do
  @moduledoc """
  Defines a block’s rule about its interior.

  `allowed` is the set of block names admitted beneath the block, and its `nil`
  is the absence of the rule, not an empty one: `nil` admits every block, where
  `[]` admits none and locks the interior empty. The two mean different pages,
  so the distinction is load-bearing and every reader of this field has to
  honor it.

  `templates` are the interiors the block offers to start from, in the order an
  inserter should show them, and each is stamped whole at insertion. A list
  rather than a single recipe, because a container that can be one thing can
  usually be three — two columns or three, a hero with a caption or without —
  and which shapes are on offer is the author’s to publish. A preset override
  replaces this rule as one unit rather than member by member: the members are
  chosen together, and a half-overridden rule has no author.

  `minimum` and `maximum` bound how many children the interior holds: `minimum`
  is a count the interior must reach, `maximum` one it may not exceed, and a
  `nil` maximum is no ceiling at all. The defaults — `0` and `nil` — declare
  nothing. The bound is a rule about the saved page, never the editor: nothing
  here prevents a breach, because an editor mid-edit legitimately passes through
  shapes the saved page may not keep, and judging a stored page against its
  declarations is another stratum’s work.

  The asymmetry with `allowed` is deliberate. For a rule about what may sit
  inside, `nil` and `[]` describe different pages, so both are needed. For a
  list of starting shapes there is no such difference — offering none and
  offering nothing are the same offer — so `templates` takes the honest empty
  value and has no third state to get wrong.

  What may sit at a document’s root is the same question asked by the container,
  with this same struct as the answer.

  ## Examples

      iex> %Containment{}
      %Containment{allowed: nil, maximum: nil, minimum: 0, templates: []}

      iex> containment = %Containment{
      ...>    templates: [%Template{label: "Template", type: "test/example"}]
      ...> }
      iex>
      iex> Enum.map(containment.templates, & &1.label)
      ["Template"]

  """
  @moduledoc since: "0.6.0"

  alias Masonree

  alias Masonree.Manifest

  alias Manifest.Template

  defstruct allowed: nil, maximum: nil, minimum: 0, templates: []

  @typedoc "Represents the containment."
  @typedoc since: "0.6.0"
  @type t() :: %__MODULE__{
          allowed: nil | [Manifest.name()],
          maximum: nil | non_neg_integer(),
          minimum: non_neg_integer(),
          templates: [Template.t()]
        }
end
