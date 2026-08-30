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

  `use` injects `Phoenix.Component`, so a block writes its markup in `~H` and
  the escaping decision is made by the template rather than chosen from a pair
  of helpers. It is `use` and not `import` because the difference is invisible
  until a block declares `attr` or `slot`, and then it is a compile error rather
  than a test failure. The map is literally named `assigns` because HEEx
  compiles against a variable of that name, and it carries `__changed__` because
  a map without that key disables change tracking across every block with no
  compiler error to say so.
  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Manifest

  alias Phoenix.LiveView.Rendered

  @typedoc "Represents the assigns."
  @typedoc since: "0.3.0"
  @type assigns() :: map()

  @typedoc "Represents the environment of the module being compiled."
  @typedoc since: "0.3.0"
  @type env() :: Macro.Env.t()

  @typedoc "Represents the code `use` injects."
  @typedoc since: "0.3.0"
  @type injection() :: Macro.t()

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type manifest() :: Manifest.t()

  @typedoc "Represents the option `use` takes, quoted."
  @typedoc since: "0.3.0"
  @type options() :: Macro.t()

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

  @doc """
  Defines `c:manifest/0` from the `@manifest` the block registered.

  The struct is built inside a module attribute, so it lives in the module’s
  literal pool and `c:manifest/0` returns a shared term rather than
  reconstructing one per call. Nothing here judges the manifest yet: validation
  joins this hook when there is a validator to run, and until then a block’s
  manifest is admitted as declared.
  """
  @doc since: "0.3.0"
  @spec __before_compile__(env()) :: injection()
  defmacro __before_compile__(_env) do
    quote do
      @impl Masonree.Block
      def manifest(), do: @manifest
    end
  end

  @doc """
  Registers the behaviour and injects `Phoenix.Component`, ignoring `options`.

  ## Example

      iex> defmodule Example do
      ...>   use Masonree.Block
      ...>
      ...>   @manifest %Manifest{name: "test/example", version: 1}
      ...> end
      iex>
      iex> Example.manifest()
      %Masonree.Manifest{
        attributes: %{},
        category: nil,
        label: nil,
        name: "test/example",
        version: 1
      }

  """
  @doc since: "0.3.0"
  @spec __using__(options()) :: injection()
  defmacro __using__(_options) do
    quote do
      use Phoenix.Component

      @before_compile unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      alias Masonree

      alias Masonree.Block
      alias Masonree.Manifest

      alias Masonree.Manifest.Attribute
    end
  end
end
