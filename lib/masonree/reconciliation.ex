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

  alias Masonree.Manifest
  alias Masonree.Node
  alias Masonree.Type

  alias Manifest.Attribute

  @typedoc "Represents the values a node holds, under repair."
  @typedoc since: "0.8.0"
  @type attributes() :: Node.attributes()

  @typedoc "Represents the node a repair is about."
  @typedoc since: "0.8.0"
  @type block_node() :: Node.t()

  @typedoc "Represents the declarations a repair fills defaults from."
  @typedoc since: "0.8.0"
  @type declarations() :: Manifest.attributes()

  @typedoc "Represents the default a repair writes for a declared silence."
  @typedoc since: "0.8.0"
  @type default() :: Type.default()

  @typedoc "Represents a repair as it is written: the key and the healed value."
  @typedoc since: "0.8.0"
  @type healed() :: {key(), value()}

  @typedoc "Represents the id of the node a repair names."
  @typedoc since: "0.8.0"
  @type id() :: Node.id()

  @typedoc "Represents an attribute key a repair names."
  @typedoc since: "0.8.0"
  @type key() :: Manifest.key()

  @typedoc "Represents how a member repaired a value it refused."
  @typedoc since: "0.8.0"
  @type mode() :: :coerced | :sanitized

  @typedoc "Represents one repair that lost something, or could not run."
  @typedoc since: "0.8.0"
  @type problem() ::
          {:dropped_attribute, id(), key()}
          | {:unrepresentable_attribute, id(), term()}

  @typedoc "Represents everything reported, in document order."
  @typedoc since: "0.8.0"
  @type problems() :: [problem()]

  @typedoc "Represents the repairs owed: each a mode, a key and a healed value."
  @typedoc since: "0.8.0"
  @type repairs() :: [{mode(), key(), value()}]

  @typedoc "Represents anything a node’s attribute map can hold, key or value."
  @typedoc since: "0.8.0"
  @type value() :: Type.value()

  @doc """
  Returns `attributes` with every declared default filled in.

  The fold of `put_default/3` over a manifest’s declarations: a `nil` default is
  never written, and a value already held is never overwritten — the fold
  inherits both rules from the function it folds, and adds none of its own. What
  a node holds after this is what its author decided plus what its block decided
  for the silences.

  ## Example

      iex> declaration = %{
      ...>   "content" => %Attribute{default: "", type: :string},
      ...>   "tag" => %Attribute{type: :string}
      ...> }
      iex>
      iex> fill_defaults(%{}, declaration)
      %{"content" => ""}

  """
  @doc since: "0.8.0"
  @spec fill_defaults(attributes(), declarations()) :: attributes()
  def fill_defaults(attributes, declarations)
      when is_map(attributes) and is_map(declarations) do
    Enum.reduce(declarations, attributes, fn {key, attribute}, acc ->
      put_default(acc, key, attribute.default)
    end)
  end

  @doc """
  Returns `attributes` with `default` written at `key`, where both halves agree.

  A `nil` default is no default at all and is never written: absence is what the
  manifest declared, and writing `nil` would turn *never decided* into *decided
  nil* for every reader that asks. A value already held is never overwritten — a
  default is what a node holds in the absence of a decision, and a held value is
  a decision, whoever made it.

  ## Example

      iex> put_default(%{"tag" => "h3"}, "tag", "h2")
      %{"tag" => "h3"}

  """
  @doc since: "0.8.0"
  @spec put_default(attributes(), key(), default()) :: attributes()
  def put_default(attributes, _key, nil) when is_map(attributes) do
    attributes
  end

  def put_default(attributes, key, default)
      when is_map(attributes) and is_binary(key) do
    Map.put_new(attributes, key, default)
  end

  @doc """
  Returns a rejection for each key `node` holds that `declared` does not.

  The twin of `Masonree.Conformance.validate_keys/2`, at the other posture: that
  report leaves the key in place and names it; this one is written for the
  repair that removes it, and once the healed document is stored the report is
  the only record the key was ever there. Every such key is named in its own
  rejection, in the order the node’s attribute map iterates, which above 32 keys
  is not the order they were written in.

  ## Example

      iex> node = %Node{
      ...>   attributes: %{"content" => "Hello, world!", "level" => 2},
      ...>   id: "n_wUnlM-3D1LCA",
      ...>   type: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> report_dropped(node, %{"content" => %Attribute{type: :string}})
      [{:dropped_attribute, "n_wUnlM-3D1LCA", "level"}]

  """
  @doc since: "0.8.0"
  @spec report_dropped(block_node(), declarations()) :: problems()
  def report_dropped(node, declarations)
      when is_struct(node, Node) and is_map(declarations) do
    for {key, _value} <- node.attributes, not Map.has_key?(declarations, key) do
      {:dropped_attribute, node.id, key}
    end
  end

  @doc """
  Returns a rejection for each attribute of `node` that would not store exactly.

  The offending key rides in the report exactly as found — an atom key arrives
  as an atom, an integer as an integer — because a restrung key in the report
  would be the very divergence the class exists to catch. The entry is judged
  whole: a key that would restring, or a value anywhere beneath it that would
  restring or refuse, is one rejection naming the key.

  What to do about one is a caller’s question; nothing here changes the node.
  The keys report in the order the node’s attribute map iterates, which above 32
  keys is not the order they were written in.

  ## Example

      iex> node = %Node{
      ...>   attributes: %{"level" => :two},
      ...>   id: "n_iaOZzKXBIQ8w",
      ...>   type: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> report_unrepresentable(node)
      [{:unrepresentable_attribute, "n_iaOZzKXBIQ8w", "level"}]

  """
  @doc since: "0.8.0"
  @spec report_unrepresentable(block_node()) :: problems()
  def report_unrepresentable(node) when is_struct(node, Node) do
    for entry = {key, _value} <- node.attributes, unrepresentable?(entry) do
      {:unrepresentable_attribute, node.id, key}
    end
  end

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

  @doc """
  Returns `attributes` narrowed to the keys `declarations` explains.

  The one repair whose loss the healed node cannot show: a key no declaration
  explains leaves, and once it has left nothing on the node says it was there —
  which is why the removal stands as its own function rather than a line in the
  assembler, so that what is removed and what is reported can be read as one
  membership. Nothing else changes: a declared key absent stays absent, filling
  it being `fill_defaults/2`’s decision, and a declared value held stays held
  whatever its type.

  ## Example

      iex> attributes = %{"content" => "Hello, world!", "level" => 2}
      iex>
      iex> declarations = %{"content" => %Attribute{type: :string}}
      iex>
      iex> take_declared(attributes, declarations)
      %{"content" => "Hello, world!"}

  """
  @doc since: "0.8.0"
  @spec take_declared(attributes(), declarations()) :: attributes()
  def take_declared(attributes, declarations)
      when is_map(attributes) and is_map(declarations) do
    keys = Map.keys(declarations)

    Map.take(attributes, keys)
  end

  @doc """
  Returns every repair `attributes` owes against `declarations`.

  A repair is owed exactly where a held value is one its declared type refuses
  and the member repairs rather than refuses: the member answers through
  `Masonree.Type.heal/3`, and a `:refused` answer matches no clause of the
  comprehension’s generator, so it is filtered by construction rather than
  tested for — what this module does with a value it cannot repair is nothing,
  and nothing is what an unmatched generator produces.

  A held `nil` owes nothing: the lattice admits it everywhere, so the question
  of repairing it never arises. An admitted value owes nothing, whoever held it.

  ## Example

      iex> declarations = %{
      ...>   "tag" => %Attribute{default: "h2", type: {:enum, ["h2", "h3"]}}
      ...> }
      iex>
      iex> take_repairs(%{"tag" => "h9"}, declarations)
      [{:coerced, "tag", "h2"}]

  """
  @doc since: "0.8.0"
  @spec take_repairs(attributes(), declarations()) :: repairs()
  def take_repairs(attributes, delarations)
      when is_map(attributes) and is_map(delarations) do
    for {key, %Attribute{default: default, type: type}} <- delarations,
        Map.has_key?(attributes, key),
        value = Map.get(attributes, key),
        not Type.admits?(type, value),
        {mode, healed} <- [Type.heal(type, value, default)] do
      {mode, key, healed}
    end
  end

  @doc """
  Returns `attributes` with one repair written at its key.

  A healed value of `nil` deletes the key rather than storing it: a declared
  default of `nil` is an attribute with no default at all, so a value coerced
  toward one is a key removed rather than a key holding `nil` — absence is what
  the manifest said, a stored `nil` is a lie a block would read as an answer,
  and the absence is exactly what `Masonree.Conformance` reports where it
  matters. Any other healed value replaces what was held.

  ## Example

      iex> write_repair(%{"tag" => "h9"}, {"tag", nil})
      %{}

  """
  @doc since: "0.8.0"
  @spec write_repair(attributes(), healed()) :: attributes()
  def write_repair(attributes, {key, nil})
      when is_map(attributes) and is_binary(key) do
    Map.delete(attributes, key)
  end

  def write_repair(attributes, {key, healed})
      when is_map(attributes) and is_binary(key) do
    Map.put(attributes, key, healed)
  end

  @spec unrepresentable?({term(), term()}) :: boolean()
  defp unrepresentable?({key, value}) do
    not is_binary(key) or not representable?(value)
  end
end
