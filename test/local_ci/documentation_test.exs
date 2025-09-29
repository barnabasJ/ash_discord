defmodule LocalCi.DocumentationTest do
  use ExUnit.Case

  test "LOCAL_CI.md file exists with comprehensive documentation" do
    assert File.exists?("LOCAL_CI.md")

    doc_content = File.read!("LOCAL_CI.md")

    # Installation instructions
    assert doc_content =~ "brew install act"
    assert doc_content =~ "curl -s https://api.github.com/repos/nektos/act"

    # Basic usage
    assert doc_content =~ "act -W .github/workflows/ci.yml"
    assert doc_content =~ "act -W .github/workflows/integration-tests.yml"
    assert doc_content =~ "act -W .github/workflows/ci-local.yml"

    # Performance expectations
    assert doc_content =~ "~60 seconds"
    assert doc_content =~ "2-5 minutes"

    # Troubleshooting section
    assert doc_content =~ "Cannot connect to Docker"
    assert doc_content =~ "docker system prune"
  end

  test "Makefile exists with proper local CI targets" do
    assert File.exists?("Makefile")

    makefile_content = File.read!("Makefile")

    # Required targets
    assert makefile_content =~ "ci-local:"
    assert makefile_content =~ "ci-test:"
    assert makefile_content =~ "ci-integration:"
    assert makefile_content =~ "ci-all:"

    # Act commands
    assert makefile_content =~ "act -W .github/workflows/ci-local.yml"
    assert makefile_content =~ "act -W .github/workflows/ci.yml"
    assert makefile_content =~ "act -W .github/workflows/integration-tests.yml"
  end

  test "documented commands work correctly" do
    # Test that basic act command doesn't fail with syntax errors
    {_output, exit_code} = System.cmd("act", ["--list"], stderr_to_stdout: true)
    assert exit_code == 0

    # Test that documented workflow files exist
    assert File.exists?(".github/workflows/ci.yml")
    assert File.exists?(".github/workflows/integration-tests.yml")
    assert File.exists?(".github/workflows/ci-local.yml")

    # Test that .actrc exists and is readable
    assert File.exists?(".actrc")
    actrc = File.read!(".actrc")
    assert actrc =~ "catthehacker/ubuntu:act-latest"
  end

  test "Makefile targets execute without syntax errors" do
    # Test help target
    {output, exit_code} = System.cmd("make", ["help"], stderr_to_stdout: true)
    assert exit_code == 0
    assert output =~ "ci-local"
    assert output =~ "ci-test"
    assert output =~ "ci-integration"
  end

  test "documentation includes all required workflows" do
    doc_content = File.read!("LOCAL_CI.md")

    # All three workflow types mentioned
    assert doc_content =~ "Main CI"
    assert doc_content =~ "Integration Tests"
    assert doc_content =~ "Local CI"

    # Performance characteristics documented
    # Main CI speed
    assert doc_content =~ "Medium"
    # Integration test speed
    assert doc_content =~ "Slow"
    # Local CI speed
    assert doc_content =~ "Fast"
  end
end
