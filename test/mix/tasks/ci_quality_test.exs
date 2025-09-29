defmodule Mix.Tasks.CiQualityTest do
  use ExUnit.Case

  test "ex_check dependency is properly configured" do
    deps = Mix.Project.config()[:deps]

    ex_check_dep =
      Enum.find(deps, fn
        {:ex_check, _version, _opts} -> true
        _ -> false
      end)

    assert ex_check_dep != nil
    {_name, version, opts} = ex_check_dep
    assert version == "~> 0.16"
    assert opts[:only] == [:dev, :test]
    assert opts[:runtime] == false
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

  test "ex_check configuration file exists and includes required tools" do
    assert File.exists?(".check.exs")

    config = Code.eval_file(".check.exs")
    tools_config = elem(config, 0)
    assert is_list(tools_config)

    tools = Keyword.get(tools_config, :tools, [])

    tool_names =
      Enum.map(tools, fn
        {name, _} -> name
        {name, _, _} -> name
      end)

    # Check that essential tools are configured
    assert :formatter in tool_names
    assert :credo in tool_names
    assert :dialyzer in tool_names
    assert :sobelow in tool_names
    assert :ex_unit in tool_names
  end
end
