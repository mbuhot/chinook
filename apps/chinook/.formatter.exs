[
  import_deps: [:ecto, :absinthe, :absinthe_relay, :dataloader],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
