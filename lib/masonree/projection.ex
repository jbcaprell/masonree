defmodule Masonree.Projection do
  @moduledoc """
  Defines the markup a document becomes.

  A block answers for one node. `Masonree.Block` fixes what a block declares and
  what it renders, and neither callback is handed a second node — walking a
  document and composing what comes back is a different job, and it lives here
  rather than on the behaviour every block implements. A block that could reach
  its siblings would be a block no developer could write alone.
  """
  @moduledoc since: "0.3.0"
end
