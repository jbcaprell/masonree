defmodule Masonree.Block do
  @moduledoc """
  Defines what a block must answer.

  A block is a module: a manifest declaring what it is, and — where it has
  markup — a render function projecting one of its nodes into that markup.

  Only `c:manifest/0` is mandatory. A block that never renders is legal and
  useful: the manifest alone answers every question but markup’s, and a block
  whose markup has not been written yet is a block whose contract already holds.

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
  @type projection() :: {rendered(), [report()]}

  @typedoc "Represents the markup a block projects."
  @typedoc since: "0.3.0"
  @type rendered() :: Rendered.t()

  @typedoc "Represents one thing a block says about its own content."
  @typedoc since: "0.3.0"
  @type report() :: term()

  @doc "Returns the block’s manifest."
  @doc since: "0.3.0"
  @callback manifest() :: manifest()

  @doc "Projects a node into markup for `assigns`."
  @doc since: "0.3.0"
  @callback render(assigns :: assigns()) :: projection()

  @optional_callbacks render: 1

  @spec admit!(Manifest.problems(), module()) :: :ok
  defp admit!([], _module), do: :ok

  defp admit!(problems, module) do
    raise ArgumentError, describe(problems, module)
  end

  @spec describe(Manifest.problems(), module()) :: String.t()
  defp describe([problem], module) do
    "#{inspect(module)} declares #{describe(problem)}"
  end

  defp describe(problems, module) do
    faults = Enum.map_join(problems, "\n", &"  - #{describe(&1)}")

    "#{inspect(module)} declares:\n#{faults}"
  end

  @spec describe(Manifest.problem()) :: String.t()
  defp describe({:bad_attribute_type, name, key}) do
    describe(name, key, "a type outside the lattice")
  end

  defp describe({:bad_cardinality, name}) do
    "#{name}, whose containment bounds contradict themselves"
  end

  defp describe({:bad_key_format, name, key}) do
    "#{name}, whose #{inspect(key)} attribute has a key of a refused shape"
  end

  defp describe({:bad_version, name}) do
    "#{name}, whose version is not a positive integer"
  end

  defp describe({:default_outside_enum, name, key}) do
    describe(name, key, "a default outside its own values")
  end

  defp describe({:default_type_mismatch, name, key}) do
    describe(name, key, "a default its type does not admit")
  end

  defp describe({:duplicate_enum_values, name, key}) do
    describe(name, key, "repeated enum values")
  end

  defp describe({:empty_enum, name, key}) do
    describe(name, key, "an enum with no values")
  end

  defp describe({:malformed_template, name}) do
    "#{name}, whose containment offers a template of a refused shape"
  end

  defp describe({:non_string_keys, name}) do
    "#{name}, whose attribute keys are not all strings"
  end

  defp describe({:required_with_default, name, key}) do
    describe(name, key, "both a default and requiredness")
  end

  defp describe({:unadmitted_template, name}) do
    "#{name}, whose containment offers a template its own rule refuses"
  end

  defp describe({:undeclared_role, name, key}) do
    describe(name, key, "no declared role, content or chrome")
  end

  defp describe({:unnamespaced_name, name}) do
    "#{name}, which is not a namespaced block name"
  end

  defp describe({:unfillable_interior, name}) do
    "#{name}, whose interior demands content and admits none"
  end

  defp describe({:unstartable_interior, name}) do
    "#{name}, whose interior demands content and offers no template"
  end

  @spec describe(Manifest.name(), Manifest.key(), String.t()) :: String.t()
  defp describe(name, key, fault) do
    "#{name}, whose #{key} attribute has #{fault}"
  end

  @spec validate!(nil | manifest(), module()) :: :ok
  defp validate!(nil, module) do
    raise ArgumentError, "#{inspect(module)} must register @manifest"
  end

  defp validate!(manifest, module) when is_struct(manifest, Manifest) do
    manifest
    |> Manifest.validate()
    |> admit!(module)
  end

  @doc """
  Defines `c:manifest/0` from the `@manifest` the block registered, judged.

  The hook validates before it defines: a block that registers no manifest, or
  one whose manifest `Masonree.Manifest.validate/1` rejects, does not compile.
  The raise names the module first, because at compile time the module is what
  the author is looking at, and it names every fault in one message — four
  faults cost one recompile rather than four.

  `c:manifest/0` answers with the same term on every call — the manifest is a
  constant of the module, never a reconstruction.
  """
  @doc since: "0.3.0"
  @spec __before_compile__(env()) :: injection()
  defmacro __before_compile__(env) do
    env.module
    |> Module.get_attribute(:manifest)
    |> validate!(env.module)

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
        containment: nil,
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
