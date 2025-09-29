defmodule Integration.WorkflowStructureTest do
  use ExUnit.Case

  test "integration workflow matrix configuration is properly structured" do
    workflow_path = ".github/workflows/integration-tests.yml"
    assert File.exists?(workflow_path)

    workflow_content = File.read!(workflow_path)

    # Test matrix configuration
    assert workflow_content =~ "phoenix"
    assert workflow_content =~ "bare"
    assert workflow_content =~ "Phoenix Latest"
    assert workflow_content =~ "Bare Elixir"

    # Test concurrency configuration
    assert workflow_content =~ "concurrency:"
    assert workflow_content =~ "integration-${{ github.ref }}"
    assert workflow_content =~ "cancel-in-progress: true"

    # Test workflow triggers
    assert workflow_content =~ "on: [push, pull_request]"
  end

  test "integration workflow is independent from main CI" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    integration_workflow = File.read!(".github/workflows/integration-tests.yml")

    # Different concurrency groups
    assert ci_workflow =~ "group: ${{ github.workflow }}-${{ github.ref }}"
    assert integration_workflow =~ "group: integration-${{ github.ref }}"

    # Independent job names
    refute integration_workflow =~ "uses: ash-project/ash"
    assert ci_workflow =~ "uses: ash-project/ash"
  end

  test "integration workflow includes required validation steps" do
    workflow_content = File.read!(".github/workflows/integration-tests.yml")

    # Check for project creation steps
    assert workflow_content =~ "mix igniter.new test_project"
    assert workflow_content =~ "mix ash_discord.install --yes"

    # Check for validation steps
    assert workflow_content =~ "test -f \"lib/test_project/discord_consumer.ex\""
    assert workflow_content =~ "grep -q \"use AshDiscord.Consumer\""
    assert workflow_content =~ "grep -q \"config :nostrum\""

    # Check for compilation and test steps
    assert workflow_content =~ "mix compile --warnings-as-errors"
    assert workflow_content =~ "mix test"
  end
end
