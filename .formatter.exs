# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ash, :spark],
  spark_locals_without_parens: [],
  locals_without_parens: [
    # AshDiscord DSL
    commands: 1,
    command: 1,
    command: 2,
    option: 2,
    option: 3,

    # Ash/Spark DSL
    attribute: 2,
    attribute: 3,
    action: 2,
    action: 3,
    argument: 2,
    argument: 3
  ],
  export: [
    locals_without_parens: [
      commands: 1,
      command: 1,
      command: 2,
      option: 2,
      option: 3
    ]
  ]
]
