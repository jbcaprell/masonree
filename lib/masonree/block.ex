defmodule Masonree.Block do
  @moduledoc """
  Defines what a block must answer.

  A block is a module: a manifest declaring what it is, and — where it has
  markup — a render function projecting one of its nodes into that markup.

  Only `c:manifest/0` is mandatory. A block that never renders is legal and
  useful: the manifest alone is what a catalog and a fingerprint will read, and
  a block whose markup has not been written yet is a block whose contract
  already holds.

  `c:render/1` receives assigns and returns markup paired with whatever the
  block wants said about its own content. The contract is the map and the pair
  and nothing further: whatever else a caller puts in those assigns is the
  caller’s to document, and a block declares nothing about its surroundings.
  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Manifest

  alias Phoenix.LiveView.Rendered

  @typedoc "Represents the assigns."
  @typedoc since: "0.3.0"
  @type assigns() :: map()

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type manifest() :: Manifest.t()

  @typedoc "Represents the markup and everything the block wants said."
  @typedoc since: "0.3.0"
  @type projection() :: {Rendered.t(), [term()]}

  @doc "Returns the block’s manifest."
  @doc since: "0.3.0"
  @callback manifest() :: manifest()

  @doc "Projects a node into markup for `assigns`."
  @doc since: "0.3.0"
  @callback render(assigns :: assigns()) :: projection()

  @optional_callbacks render: 1
end
