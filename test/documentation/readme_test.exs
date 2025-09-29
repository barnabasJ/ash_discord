defmodule Documentation.ReadmeTest do
  use ExUnit.Case

  test "README.md includes new CI architecture documentation" do
    readme_content = File.read!("README.md")

    # CI badge updates
    assert readme_content =~ "[![CI]"
    assert readme_content =~ "[![Integration Tests]"

    # CI/Development section exists
    assert readme_content =~ "## 🔧 CI/Development"

    # Centralized CI documentation
    assert readme_content =~ "Centralized CI"
    assert readme_content =~ "ash-project/ash/.github/workflows/ash-ci.yml@main"

    # Integration testing documentation
    assert readme_content =~ "Integration Testing"
    assert readme_content =~ "Phoenix + Bare Elixir"

    # Local development documentation
    assert readme_content =~ "Local Development"
    assert readme_content =~ "<60s"
    assert readme_content =~ "10x Performance"

    # Security scanning mentioned
    assert readme_content =~ "Sobelow"
    assert readme_content =~ "hex.audit"

    # Local CI commands documented
    assert readme_content =~ "make ci-local"
    assert readme_content =~ "LOCAL_CI.md"
  end

  test "CONTRIBUTING.md includes new CI requirements" do
    contributing_content = File.read!("CONTRIBUTING.md")

    # Local CI Development section exists
    assert contributing_content =~ "### Local CI Development (New!)"

    # Act tool installation
    assert contributing_content =~ "brew install act"

    # New quality commands
    assert contributing_content =~ "mix check"
    assert contributing_content =~ "mix sobelow --config"
    assert contributing_content =~ "mix deps.audit"

    # Fast local CI recommendations
    assert contributing_content =~ "make ci-local"
    assert contributing_content =~ "~60 seconds"

    # Updated PR requirements
    assert contributing_content =~ "RECOMMENDED: Fast local CI"

    # Reference to LOCAL_CI.md
    assert contributing_content =~ "[Local CI Guide](LOCAL_CI.md)"
  end

  test "all documented links are valid file references" do
    readme_content = File.read!("README.md")
    contributing_content = File.read!("CONTRIBUTING.md")

    # LOCAL_CI.md exists and is referenced
    assert readme_content =~ "[act tool](LOCAL_CI.md)"
    assert contributing_content =~ "[Local CI Guide](LOCAL_CI.md)"
    assert File.exists?("LOCAL_CI.md")

    # CI workflow files exist
    assert File.exists?(".github/workflows/ci.yml")
    assert File.exists?(".github/workflows/integration-tests.yml")
    assert File.exists?(".github/workflows/ci-local.yml")

    # Makefile exists and has referenced targets
    assert File.exists?("Makefile")
    makefile = File.read!("Makefile")
    assert makefile =~ "ci-local:"
    assert makefile =~ "ci-integration:"
  end

  test "badges point to correct workflow files" do
    readme_content = File.read!("README.md")

    # Check CI badge
    assert readme_content =~ "workflows/CI/badge.svg"

    # Check Integration Tests badge
    assert readme_content =~ "workflows/Integration%20Tests/badge.svg"

    # Verify workflow names match
    ci_workflow = File.read!(".github/workflows/ci.yml")
    integration_workflow = File.read!(".github/workflows/integration-tests.yml")

    assert ci_workflow =~ "name: CI"
    assert integration_workflow =~ "name: Integration Tests"
  end

  test "documented commands are executable" do
    # Test that documented dependencies exist in mix.exs
    mix_content = File.read!("mix.exs")
    assert mix_content =~ "ex_check"
    assert mix_content =~ "deps.audit"

    # Test that sobelow dependency exists
    assert mix_content =~ "sobelow"

    # Test that documented files exist
    assert File.exists?(".sobelow-conf")
    assert File.exists?(".actrc")
  end
end
