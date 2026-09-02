defmodule Masonree.Manifest do
  @moduledoc """
  Defines what a block declares about itself.

  A manifest carries a block’s name, its version, how it announces itself in
  an editor, the attributes whose values a node of that type may hold, and —
  where the block is a container — the rule about its interior. It is to
  answer belongs elsewhere, which is what lets a manifest be checked at its
  own compile.

  Only `attributes` describes anything a node stores. A node’s `attributes` hold
  values whose meaning is fixed here; the rest is code. `label` and `category`
  are display and may be reworded freely; an attribute cannot, because changing
  one orphans stored content. `containment` rules the interior — what may sit
  inside, how many, and what a container starts as — and tightening it makes no
  stored page unreadable: a page is judged against it, never re-parsed by it.

  A version belongs to the block rather than to the library: it counts the
  migrations a node of this type may have to walk. It is 1 until the block’s
  stored shape first moves.

  ## Example

      iex> %Manifest{name: "test/example", version: 1}
      %Manifest{
        attributes: %{},
        category: nil,
        containment: nil,
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
  alias Manifest.Containment

  @enforce_keys [:name, :version]
  defstruct attributes: %{},
            category: nil,
            containment: nil,
            label: nil,
            name: nil,
            version: nil

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
          {:bad_attribute_type, name(), term()}
          | {:bad_cardinality, name()}
          | {:bad_key_format, name(), key()}
          | {:bad_version, name()}
          | {:default_outside_enum, name(), term()}
          | {:default_type_mismatch, name(), term()}
          | {:duplicate_enum_values, name(), term()}
          | {:empty_enum, name(), term()}
          | {:non_string_keys, name()}
          | {:required_with_default, name(), term()}
          | {:undeclared_role, name(), term()}
          | {:unfillable_interior, name()}
          | {:unnamespaced_name, name()}
          | {:unstartable_interior, name()}

  @typedoc "Represents every rejection found."
  @typedoc since: "0.5.0"
  @type problems() :: [problem()]

  @typedoc "Represents the manifest."
  @typedoc since: "0.3.0"
  @type t() :: %__MODULE__{
          attributes: attributes(),
          category: nil | String.t(),
          containment: nil | Containment.t(),
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
  @roles ~W[chrome content]a

  @doc """
  Returns the namespace of `name`, or `nil` where it carries none.

  A name is namespaced only when a single `/` splits it into two non-empty
  halves. The reading is deliberately tolerant, and the tolerance is for a
  caller that does not exist yet: the same question will be put to `type`
  strings read out of stored content, which never passed through any judgment,
  so this answers about any binary rather than assuming a well-formed one.
  Nothing in the library asks it that way today — `validate_name/1` judges a
  declaration a person wrote, and judges it strictly — so until that stratum
  stands, the tolerance is a shape held open and not a service rendered.

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
  Returns whether the block declares an interior no editor can start.

  A containment with a floor above zero requires the interior to hold
  something from the first save, and templates are the only way an editor puts
  something there without authoring it — so a floor with no template is a demand
  with no way to meet it. The two declarations are each fine alone: a zero floor
  needs no template, and a template list may sit beside any floor. Only the pair
  is refused.

  A block with no containment declares no interior at all, and a block with no
  interior cannot be unstartable.

  ## Examples

      iex> manifest = %Manifest{
      ...>   containment: %Containment{minimum: 1},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> unstartable?(manifest)
      true

      iex> unstartable?(%Manifest{name: "test/example", version: 1})
      false

  """
  @doc since: "0.6.0"
  @spec unstartable?(t()) :: boolean()
  def unstartable?(%__MODULE__{containment: nil}), do: false

  def unstartable?(%__MODULE__{containment: containment}) do
    containment.minimum > 0 and containment.templates == []
  end

  @doc """
  Returns every rejection `manifest` carries, sorted, or `[]` where well formed.

  Every check runs and every fault is reported: a manifest with four faults
  names four, and an author reading a build failure fixes them in one pass
  rather than one compile each. One fault is still one rejection — a malformed
  type is never reported a second time as the default judged against it — and
  the report is sorted, so it is the same list whatever order the attribute map
  iterates in, which above 32 keys is not the order it was written in.

  Sorting is by term order, which compares tuples by size before contents, so
  every block-level problem precedes every attribute-level one and a reader
  meets this manifest is wrong before this attribute is wrong. That falls out of
  tuple sizing rather than being arranged, and it is the order worth having.

  Only what a block can know about itself is checked. Whether a name is unique,
  or collides with another block’s — anything needing a second block to answer —
  belongs to whatever holds the blocks, not here.

  ## Examples

      iex> validate(%Manifest{name: "test/example", version: 1})
      []

      iex> validate(%Manifest{name: "example", version: 0})
      [{:bad_version, "example"}, {:unnamespaced_name, "example"}]

  """
  @doc since: "0.5.0"
  @spec validate(t()) :: problems()
  def validate(manifest) when is_struct(manifest, __MODULE__) do
    reports = [
      validate_defaults(manifest),
      validate_duplicates(manifest),
      validate_enums(manifest),
      validate_format(manifest),
      validate_keys(manifest),
      validate_name(manifest),
      validate_requiredness(manifest),
      validate_roles(manifest),
      validate_scalars(manifest),
      validate_types(manifest),
      validate_version(manifest)
    ]

    reports
    |> Enum.concat()
    |> Enum.sort()
  end

  @doc """
  Returns the rejection where a containment’s bounds contradict themselves.

  A floor is a count, so it is an integer of at least zero; a ceiling is
  `nil` — no ceiling at all — or an integer no lower than the floor. A
  ceiling below the floor describes an interior no page can hold: every
  count breaches one bound or the other, so the declaration is refused
  before a page has to discover it. A block with no containment declares no
  bounds, and nothing is judged.

  ## Examples

      iex> manifest = %Manifest{
      ...>   containment: %Containment{maximum: 3, minimum: 1},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_cardinality(manifest)
      []

      iex> manifest = %Manifest{
      ...>   containment: %Containment{maximum: 1, minimum: 2},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_cardinality(manifest)
      [{:bad_cardinality, "test/example"}]

  """
  @doc since: "0.6.0"
  @spec validate_cardinality(t()) :: problems()
  def validate_cardinality(%__MODULE__{containment: nil}), do: []

  def validate_cardinality(%__MODULE__{} = manifest) do
    manifest.containment
    |> bad_cardinality?()
    |> report_containment(manifest.name, :bad_cardinality)
  end

  @doc """
  Returns a rejection for each enum attribute whose default its values refuse.

  The membership question, asked of the declaration about itself: an enum admits
  exactly what its list holds, so a default outside the list would be written
  into a node as a value the attribute then refuses — a declaration quarreling
  with itself, caught before either half can win. Membership is the whole
  comparison, because an enum has no base type for a default to mismatch. A
  `nil` default is absence and absence is never wrong; a payload that is not a
  list is a different fault, reported once, as itself.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{
      ...>     "tag" => %Attribute{default: "h9", type: {:enum, ["h2", "h3"]}}
      ...>   },
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_defaults(manifest)
      [{:default_outside_enum, "test/example", "tag"}]

  """
  @doc since: "0.5.0"
  @spec validate_defaults(t()) :: problems()
  def validate_defaults(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&default_outside_enum?/1)
    |> report_attributes(name, :default_outside_enum)
  end

  @doc """
  Returns a rejection for each enum attribute that repeats a value.

  An enum’s values are a set an author writes as a list, and a repeated entry is
  always a mistake rather than a wider set: nothing a node can hold
  distinguishes an enum from the same enum with a value repeated, so the
  repetition can only ever mislead a reader about how many choices there are.
  Repetition is judged strictly — `1` and `1.0` are two entries, not one
  repeated — and the copies need not be adjacent to be found.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{"tag" => %Attribute{type: {:enum, ["h2", "h2"]}}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_duplicates(manifest)
      [{:duplicate_enum_values, "test/example", "tag"}]

  """
  @doc since: "0.5.0"
  @spec validate_duplicates(t()) :: problems()
  def validate_duplicates(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&duplicate_enum_values?/1)
    |> report_attributes(name, :duplicate_enum_values)
  end

  @doc """
  Returns a rejection for each enum attribute declared with no values.

  `{:enum, []}` is legible to the lattice and useless to everything above it: no
  value a node could hold is admissible under it, no default can satisfy it, and
  an inspector generated from it would draw a select with nothing to select.
  Emptiness is a rule about a usable declaration rather than a legible one,
  which is why the lattice does not refuse it and this function does. A payload
  that is not a list at all is a different fault with its own name, and is not
  repeated here.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{"tag" => %Attribute{type: {:enum, []}}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_enums(manifest)
      [{:empty_enum, "test/example", "tag"}]

  """
  @doc since: "0.5.0"
  @spec validate_enums(t()) :: problems()
  def validate_enums(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&empty_enum?/1)
    |> report_attributes(name, :empty_enum)
  end

  @doc """
  Returns a rejection where the block declares an interior nothing may fill.

  An empty `allowed` admits no block, and a floor above zero demands at least
  one: together they describe an interior that must hold what it may not, a page
  no editor can save as valid. Either is fine alone — an empty list over a zero
  floor is an interior sealed on purpose, and a floor may stand under any list
  that names something. An absent `allowed` is no rule at all rather than an
  empty one, and admits every block, so it never contradicts a floor.

  An unfillable interior with no template is unstartable as well, and
  `validate_startability/1` names that on its own, because the two are resolved
  by different edits. A block with no containment declares no interior, and
  nothing is judged.

  ## Example

      iex> manifest = %Manifest{
      ...>   containment: %Containment{allowed: [], minimum: 1},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_fillability(manifest)
      [{:unfillable_interior, "test/example"}]

  """
  @doc since: "0.6.0"
  @spec validate_fillability(t()) :: problems()
  def validate_fillability(%__MODULE__{containment: nil}), do: []

  def validate_fillability(%__MODULE__{} = manifest) do
    manifest.containment
    |> unfillable_interior?()
    |> report_containment(manifest.name, :unfillable_interior)
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

      iex> manifest = %Manifest{
      ...>   attributes: %{"tag name" => %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_format(manifest)
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

      iex> manifest = %Manifest{
      ...>   attributes: %{content: %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_keys(manifest)
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
  Returns a rejection for each attribute whose requiredness its default cancels.

  `required: true` means exactly one thing: no honest default exists — an image
  source, a link target, anything whose placeholder would render as a lie. An
  attribute that also carries a default can never be absent, so its requiredness
  can never produce a finding: the two declarations, side by side, cancel. The
  pair is refused rather than left to mean nothing, because a contract that
  cannot fire teaches its reader a rule the code does not keep.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{
      ...>     "src" => %Attribute{default: "", required: true, type: :string}
      ...>   },
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_requiredness(manifest)
      [{:required_with_default, "test/example", "src"}]

  """
  @doc since: "0.5.0"
  @spec validate_requiredness(t()) :: problems()
  def validate_requiredness(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&required_with_default?/1)
    |> report_attributes(name, :required_with_default)
  end

  @doc """
  Returns a rejection for each attribute choosing neither content nor chrome.

  Every attribute is one or the other — what the page says, or how it presents —
  and the choice is the author’s, because nothing mechanical can tell a headline
  from a layout flag. The struct cannot enforce it: the lock that reads the
  field is declared by a container, and the attributes it freezes belong to that
  container’s children, so the precondition can never be checked where its
  consumer is written and is checked here instead, on every attribute of every
  block. A `nil` is refused exactly as a misspelling is — absence and a wrong
  answer are the same failure to choose.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{"content" => %Attribute{type: :string}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_roles(manifest)
      [{:undeclared_role, "test/example", "content"}]

  """
  @doc since: "0.5.0"
  @spec validate_roles(t()) :: problems()
  def validate_roles(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&role_undeclared?/1)
    |> report_attributes(name, :undeclared_role)
  end

  @doc """
  Returns a rejection for each scalar attribute whose default its type refuses.

  A default is a stored value waiting to happen, so it is judged exactly as a
  stored value would be: by asking the type. The check runs only where the type
  itself is declarable — a malformed declaration reports once, as what it is,
  and never a second time for a default judged against a type that does not
  exist, because one fault is one fault. An enum’s default is a membership
  question rather than a type question and has its own rule; a `nil` default is
  absence, and absence is never a wrong value.

  ## Example

      iex> manifest = %Manifest{
      ...>   attributes: %{"rank" => %Attribute{default: "2", type: :number}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_scalars(manifest)
      [{:default_type_mismatch, "test/example", "rank"}]

  """
  @doc since: "0.5.0"
  @spec validate_scalars(t()) :: problems()
  def validate_scalars(%__MODULE__{attributes: attributes, name: name}) do
    attributes
    |> take_attributes(&default_type_mismatch?/1)
    |> report_attributes(name, :default_type_mismatch)
  end

  @doc """
  Returns a rejection where the block declares an interior no editor can start.

  The question `unstartable?/1` asks, reported: a floor above zero with no
  template offered is a demand the editor has no way to meet, and a page that no
  sequence of editor actions can make valid is refused at compile rather than
  discovered at the first save. Either declaration is fine alone, and the
  rejection names the block rather than the floor or the template list, because
  the fix is a choice between the two.

  A block with no containment declares no interior, and nothing is judged.

  ## Example

      iex> manifest = %Manifest{
      ...>   containment: %Containment{minimum: 1},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_startability(manifest)
      [{:unstartable_interior, "test/example"}]

  """
  @doc since: "0.6.0"
  @spec validate_startability(t()) :: problems()
  def validate_startability(%__MODULE__{containment: nil}), do: []

  def validate_startability(%__MODULE__{} = manifest) do
    manifest
    |> unstartable?()
    |> report_containment(manifest.name, :unstartable_interior)
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

      iex> manifest = %Manifest{
      ...>   attributes: %{"tag" => %Attribute{type: :bool}},
      ...>   name: "test/example",
      ...>   version: 1
      ...> }
      iex>
      iex> validate_types(manifest)
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

  @spec bad_cardinality?(Containment.t()) :: boolean()
  defp bad_cardinality?(%Containment{maximum: maximum, minimum: minimum}) do
    not (bounded_minimum?(minimum) and bounded_maximum?(maximum, minimum))
  end

  @spec bad_key_format?(term()) :: boolean()
  defp bad_key_format?(key) when is_binary(key), do: not Regex.match?(@key, key)
  defp bad_key_format?(_key), do: false

  @spec bounded_maximum?(term(), term()) :: boolean()
  defp bounded_maximum?(nil, _minimum), do: true

  defp bounded_maximum?(maximum, minimum) do
    is_integer(maximum) and maximum >= minimum
  end

  @spec bounded_minimum?(term()) :: boolean()
  defp bounded_minimum?(minimum), do: is_integer(minimum) and minimum >= 0

  @spec default_outside_enum?(Attribute.t()) :: boolean()
  defp default_outside_enum?(%Attribute{default: nil}), do: false

  defp default_outside_enum?(%Attribute{type: {:enum, values}} = attribute)
       when is_list(values) do
    attribute.default not in values
  end

  defp default_outside_enum?(_attribute), do: false

  @spec default_type_mismatch?(Attribute.t()) :: boolean()
  defp default_type_mismatch?(%Attribute{type: {:enum, _values}}), do: false

  defp default_type_mismatch?(%Attribute{default: default, type: type}) do
    Type.declarable?(type) and not Type.admits?(type, default)
  end

  @spec duplicate_enum_values?(Attribute.t()) :: boolean()
  defp duplicate_enum_values?(%Attribute{type: {:enum, values}})
       when is_list(values) do
    values != Enum.uniq(values)
  end

  defp duplicate_enum_values?(_attribute), do: false

  @spec empty_enum?(Attribute.t()) :: boolean()
  defp empty_enum?(%Attribute{type: {:enum, []}}), do: true
  defp empty_enum?(_attribute), do: false

  @spec non_string_key?(term()) :: boolean()
  defp non_string_key?(key), do: not is_binary(key)

  @spec report_attributes([declaration()], name(), atom()) :: problems()
  defp report_attributes(declarations, name, problem) do
    for {key, _attribute} <- declarations, do: {problem, name, key}
  end

  @spec report_containment(boolean(), name(), atom()) :: problems()
  defp report_containment(true, name, problem), do: [{problem, name}]
  defp report_containment(false, _name, _problem), do: []

  @spec report_format([key()], name()) :: problems()
  defp report_format(keys, name) do
    for key <- keys, do: {:bad_key_format, name, key}
  end

  @spec report_keys([term()], name()) :: problems()
  defp report_keys([], _name), do: []
  defp report_keys(_keys, name), do: [{:non_string_keys, name}]

  @spec report_name(boolean(), name()) :: problems()
  defp report_name(false, name), do: [{:unnamespaced_name, name}]
  defp report_name(true, _name), do: []

  @spec required_with_default?(Attribute.t()) :: boolean()
  defp required_with_default?(%Attribute{default: nil}), do: false
  defp required_with_default?(%Attribute{required: required}), do: required

  @spec role_undeclared?(Attribute.t()) :: boolean()
  defp role_undeclared?(%Attribute{role: role}), do: role not in @roles

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

  @spec unfillable_interior?(Containment.t()) :: boolean()
  defp unfillable_interior?(%Containment{allowed: [], minimum: minimum}) do
    minimum > 0
  end

  defp unfillable_interior?(_containment), do: false
end
