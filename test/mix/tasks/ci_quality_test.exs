defmodule Mix.Tasks.CiQualityTest do
  use ExUnit.Case

  test "quality.full alias includes all required tools" do
    aliases = Mix.Project.config()[:aliases]

    assert aliases[:"quality.full"] == [
             "format",
             "credo --strict",
             "dialyzer",
             "sobelow --config"
           ]
  end

  test "deps.audit alias includes audit tools" do
    aliases = Mix.Project.config()[:aliases]

    assert aliases[:"deps.audit"] == [
             "hex.audit",
             "deps.unlock --check-unused"
           ]
  end

  test "sobelow dependency is properly configured" do
    deps = Mix.Project.config()[:deps]

    sobelow_dep =
      Enum.find(deps, fn
        {:sobelow, _version, _opts} -> true
        _ -> false
      end)

    assert sobelow_dep != nil
    {_name, version, opts} = sobelow_dep
    assert version == "~> 0.14"
    assert opts[:only] == [:dev, :test]
    assert opts[:runtime] == false
  end

  test "mix deps.audit runs without errors" do
    {output, exit_code} = System.cmd("mix", ["hex.audit"], stderr_to_stdout: true)
    assert exit_code == 0
    assert output =~ "No retired packages found" or output =~ "packages found"
  end

  test "sobelow configuration file exists" do
    assert File.exists?(".sobelow-conf")

    config = Code.eval_file(".sobelow-conf")
    assert is_list(elem(config, 0))
  end
end
