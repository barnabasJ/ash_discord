[
  ## Run tools in parallel for speed
  parallel: true,

  ## Continue running tools even if some fail
  halt_on_failure: false,

  ## Tools configuration
  tools: [
    # Code formatting
    {:formatter, enabled: true},

    # Static analysis
    {:credo, "mix credo --strict"},

    # Type checking (slower, run with lower priority)
    {:dialyzer, enabled: true, order: 10},

    # Security scanning (configured to not fail on findings)
    {:sobelow, "mix sobelow --config --exit-on medium", order: 5},

    # Dependency audit
    {:hex_audit, "mix hex.audit"},
    {:deps_unused, "mix deps.unlock --check-unused"},

    # Test execution
    {:ex_unit, "mix test --warnings-as-errors"}
  ]
]
