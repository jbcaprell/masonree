defmodule Masonree.ConformanceTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.7.0"

  use ExUnit.Case, async: true

  alias Masonree

  alias Masonree.Conformance

  doctest Conformance, import: true
end
