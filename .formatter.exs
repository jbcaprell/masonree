[
  import_deps: [:ecto],
  inputs: [
    ".{boundary,credo,dialyzer,formatter}.exs",
    "{lib,support,test}/**/*.{ex,exs}",
    "mix.{exs,lock}"
  ],
  line_length: 80,
  locals_without_parens: [attr: 2, attr: 3, slot: 1, slot: 2, slot: 3],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]
