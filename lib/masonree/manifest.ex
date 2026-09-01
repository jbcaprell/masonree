defmodule Masonree.Manifest do
  @moduledoc """
  Defines what a block declares about itself.

  A manifest carries a block’s name, its version, how it announces itself in an
  editor, and the attributes whose values a node of that type may hold. It is
  the whole of what a block knows about itself: anything needing a second block
  to answer belongs elsewhere, which is what lets a manifest be checked at its
  own compile.

  Only `attributes` describes anything a node stores. A node’s `attributes` hold
  values whose meaning is fixed here; the rest is code. `label` and `category`
  are display and may be reworded freely; an attribute cannot, because changing
  one orphans stored content.

  A version belongs to the block rather than to the library: it counts the
  migrations a node of this type may have to walk. It is 1 until the block’s
  stored shape first moves.

  ## Example

      iex> %Manifest{name: "test/example", version: 1}
      %Manifest{
        attributes: %{},
        category: nil,
        label: nil,
        name: "test/example",
        version: 1
      }

  """
  @moduledoc since: "0.3.0"

  alias Masonree

  alias Masonree.Manifest
  alias Masonree.Type

  alias Manifest.Attribute

  @enforce_keys [:name, :version]
  defstruct attributes: %{}, category: nil, label: nil, name: nil, version: nil

  @typedoc "Represents the declarations a block holds, keyed by attribute."
  @typedoc since: "0.5.0"
  @type attributes() :: %{key() => Attribute.t()}

  @typedoc "Represents an attribute’s key in the manifest."
  @typedoc since: "0.3.0"
  @type key() :: String.t()

  @typedoc "Represents the block’s name."
  @typedoc since: "0.3.0"
  @type name() :: String.t()

  @typedoc "Represents the owning half of a namespaced name."
  @typedoc since: "0.5.0"
  @type namespace() :: String.t()

  @typedoc "Represents a rejection, naming the block it was found in."
  @typedoc since: "0.5.0"
  @type problem() ::
          {:bad_attribute_type, name(), key()}
          | {:bad_key_format, name(), key()}
          | {:bad_version, name()}
          | {:non_string_keys, name()}
          | {:unnamespaced_name, name()}

  @typedoc "Represents every rejection found."
  @typedoc since: "0.5.0"
  @type problems() :: [problem()]

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          attributes: attributes(),
          category: nil | String.t(),
          label: nil | String.t(),
          name: name(),
          version: version()
        }

  @typedoc "Represents the block’s version, a count of its migrations."
  @typedoc since: "0.3.0"
  @type version() :: pos_integer()
  @typep declaration() :: {key(), Attribute.t()}
  @typep predicate() :: (Attribute.t() -> boolean())

  @key ~r"\A[^[:space:][:cntrl:]]+\z"u
  @name ~r"\A[a-z][a-z0-9-]*/[a-z][a-z0-9-]*\z"

  @doc """
  Returns the namespace of `name`, or `nil` where it carries none.

  A name is namespaced only when a single `/` splits it into two non-empty
  halves. The reading is deliberately tolerant: this question is also asked
  about `type` strings read out of stored content, which never passed through
  any judgment, so it answers about any binary rather than assuming a
  well-formed one.

  ## Examples

      iex> get_namespace("core/paragraph")
      "core"

      iex> get_namespace("example")
      nil

  """
  @doc since: "0.5.0"
  @spec get_namespace(name()) :: nil | namespace()
  def get_namespace(name) when is_binary(name) do
    name
    |> String.split("/")
    |> take_namespace()
  end

  @doc """
  Returns a rejection for each attribute key of a shape no key may have.

  A key is refused for its shape and never for its style: one or more
  characters, none of them whitespace and none a control character.
  `snake_case`, `camelCase`, `kebab-case` and `dotted.name` all pass, and an
  empty key, a NUL, a non-breaking space and a trailing newline are all refused
  — the whitespace and control classes are Unicode-wide, because a key pasted
  out of a design tool can carry U+00A0 where a reader sees an ordinary space.

  Every offending key is named in its own rejection, so an author fixing
  one is not left to rediscover its sibling on the next compile. A key that is
  not a string at all is not judged here — that is a different fault with its
  own name.

  ## Example

      iex> validate_format(%Manifest{
      ...>   attributes: %{"tag name" => %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> })
      [{:bad_key_format, "test/example", "tag name"}]

  """
  @doc since: "0.5.0"
  @spec validate_format(t()) :: problems()
  def validate_format(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> Map.keys()
    |> Enum.filter(&bad_key_format?/1)
    |> report_format(name)
  end

  @doc """
  Returns the rejection where any attribute key is not a string.

  An attribute key is a jsonb key, and jsonb keys are strings: an atom or an
  integer written here would be restrung by the column into something no
  manifest declares, so the declaration is refused before storage can
  reinterpret it. The rejection is a single two-tuple however many keys offend,
  because a manifest written with atom keys is usually written with atom keys
  throughout, and naming one invites fixing one.

  ## Example

      iex> validate_keys(%Manifest{
      ...>   attributes: %{content: %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> })
      [{:non_string_keys, "test/example"}]

  """
  @doc since: "0.5.0"
  @spec validate_keys(t()) :: problems()
  def validate_keys(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> Map.keys()
    |> Enum.filter(&non_string_key?/1)
    |> report_keys(name)
  end

  @doc """
  Returns the rejection where `manifest`’s name is not a namespaced name.

  A block’s name is two lowercase halves split by one `/` — a namespace and a
  local name, each beginning with a letter and continuing in letters, digits and
  hyphens. A trailing newline is refused: `"test/example\\n"` prints identically
  to a legal name everywhere a name appears, and is not one.

  The check is strict where `get_namespace/1` is tolerant: this judges a
  declaration a person wrote, and the other reads whatever a stored `type`
  string happens to hold. The strictness fixes a client’s namespace as lowercase
  letters, digits and hyphens forever, and that cost is taken knowingly — a name
  grammar loosened later admits names it once refused, where one tightened later
  orphans names it once admitted.

  ## Examples

      iex> validate_name(%Manifest{name: "test/example", version: 1})
      []

      iex> validate_name(%Manifest{name: "Example", version: 1})
      [{:unnamespaced_name, "Example"}]

  """
  @doc since: "0.5.0"
  @spec validate_name(t()) :: problems()
  def validate_name(%__MODULE__{name: name}) do
    name
    |> String.match?(@name)
    |> report_name(name)
  end

  @doc """
  Returns a rejection for each attribute whose type the lattice refuses.

  The question is `Masonree.Type.declarable?/1`’s, asked attribute by attribute,
  and this module adds nothing to the answer: what a type is was never the
  manifest’s to know, and a list of admissible types kept here would be a second
  copy of the lattice for the two to disagree over. This check is what makes the
  lattice’s closure true of a declaration at the author’s compile rather than of
  a stored value at a visitor’s read — `:integer` refused here costs an author a
  recompile, where admitted it would cost a client a page.

  What a well-shaped payload contains is not judged here. `{:enum, []}` declares
  a legible type with no usable values, and emptiness has its own name.

  ## Example

      iex> validate_types(%Manifest{
      ...>   attributes: %{"tag" => %Attribute{type: :bool}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> })
      [{:bad_attribute_type, "test/example", "tag"}]

  """
  @doc since: "0.5.0"
  @spec validate_types(t()) :: problems()
  def validate_types(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&bad_attribute_type?/1)
    |> report_attributes(name, :bad_attribute_type)
  end

  @doc """
  Returns the rejection where `manifest`’s version is not a positive integer.

  A version counts the migrations a node of this type may have to walk, so the
  count begins at 1 and moves only when the block’s stored shape does. Zero is
  as wrong as a float or a string: none of them is a place a migration walk can
  stand. The struct’s type says `pos_integer()`; this check is what holds a
  hand-built declaration to it.

  ## Examples

      iex> validate_version(%Manifest{name: "test/example", version: 1})
      []

      iex> validate_version(%Manifest{name: "test/example", version: 0})
      [{:bad_version, "test/example"}]

  """
  @doc since: "0.5.0"
  @spec validate_version(t()) :: problems()
  def validate_version(%__MODULE__{version: version})
      when is_integer(version) and version > 0 do
    []
  end

  def validate_version(%__MODULE__{name: name}) do
    [{:bad_version, name}]
  end

  @spec bad_attribute_type?(Attribute.t()) :: boolean()
  defp bad_attribute_type?(%Attribute{type: type}) do
    not Type.declarable?(type)
  end

  @spec bad_key_format?(term()) :: boolean()
  defp bad_key_format?(key) when is_binary(key), do: not Regex.match?(@key, key)
  defp bad_key_format?(_key), do: false

  @spec non_string_key?(term()) :: boolean()
  defp non_string_key?(key), do: not is_binary(key)

  @spec report_attributes([declaration()], name(), atom()) :: problems()
  defp report_attributes(declarations, name, problem) do
    for {key, _attribute} <- declarations, do: {problem, name, key}
  end

  @spec report_format([key()], name()) :: problems()
  defp report_format(keys, name) do
    for key <- keys, do: {:bad_key_format, name, key}
  end

  @spec report_name(boolean(), name()) :: problems()
  defp report_name(false, name), do: [{:unnamespaced_name, name}]
  defp report_name(true, _name), do: []

  @spec report_keys([term()], name()) :: problems()
  defp report_keys([], _name), do: []
  defp report_keys(_keys, name), do: [{:non_string_keys, name}]

  @spec take_attributes(attributes(), predicate()) :: [declaration()]
  defp take_attributes(attributes, predicate) do
    Enum.filter(attributes, fn {_key, attribute} -> predicate.(attribute) end)
  end

  @spec take_namespace([String.t()]) :: nil | namespace()
  defp take_namespace([namespace, local_name])
       when namespace != "" and local_name != "" do
    namespace
  end

  defp take_namespace(_parts), do: nil
end
