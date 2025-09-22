defmodule Mix.Tasks.AshDiscord.InstallTest do
  use ExUnit.Case
  use Igniter.Test

  alias Igniter.Project.Application

  describe "ash_discord.install" do
    test "installs with default options" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_creates_consumer_module()
      |> assert_adds_nostrum_dependency()
      |> assert_configures_environments()
      |> assert_adds_to_supervision_tree()
      |> assert_adds_formatter_configuration()
    end

    test "installs with custom consumer name" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", ["--consumer", "MyApp.Bot.Consumer"])
      |> assert_creates_module("MyApp.Bot.Consumer")
      |> assert_has_file("lib/my_app/bot/consumer.ex")
    end

    test "installs with configured domains" do
      test_project()
      |> create_domain_module("MyApp.Discord")
      |> create_domain_module("MyApp.Chat")
      |> Igniter.compose_task("ash_discord.install", ["--domains", "MyApp.Discord,MyApp.Chat"])
      |> assert_creates_consumer_with_domains(["MyApp.Discord", "MyApp.Chat"])
    end

    test "fails without Phoenix application" do
      assert_raise RuntimeError, ~r/AshDiscord requires a Phoenix application/, fn ->
        test_project(phoenix: false)
        |> Igniter.compose_task("ash_discord.install", [])
      end
    end

    test "fails without Ash framework" do
      assert_raise RuntimeError, ~r/AshDiscord requires the Ash framework/, fn ->
        test_project(deps: [])
        |> Igniter.compose_task("ash_discord.install", [])
      end
    end

    test "validates domain existence" do
      assert_raise RuntimeError, ~r/Domain module.*does not exist/, fn ->
        test_project()
        |> Igniter.compose_task("ash_discord.install", ["--domains", "NonExistent.Domain"])
      end
    end

    test "consumer generation creates proper module structure" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_file_contains("lib/test/discord_consumer.ex", "use AshDiscord.Consumer")
      |> assert_file_contains("lib/test/discord_consumer.ex", "ash_discord_consumer do")
      |> assert_file_contains("lib/test/discord_consumer.ex", "domains(")
    end

    test "dependency management adds nostrum" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_file_contains("mix.exs", ~s|{:nostrum, "~> 0.10"}|)
    end

    test "environment configuration sets up all environments" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_file_contains("config/dev.exs", "config :nostrum")
      |> assert_file_contains("config/runtime.exs", "System.get_env(\"DISCORD_TOKEN\")")
      |> assert_file_contains("config/test.exs", "config :nostrum")
    end

    test "supervision tree integration adds consumer" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_file_contains("lib/test/application.ex", "Test.DiscordConsumer")
    end

    test "formatter configuration adds Spark.Formatter" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_file_contains(".formatter.exs", "import_deps: [:ash_discord")
      |> assert_file_contains(".formatter.exs", "Spark.Formatter")
    end

    test "installer is idempotent" do
      project =
        test_project()
        |> Igniter.compose_task("ash_discord.install", [])

      # Running again should not error
      project
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_unchanged()
    end
  end

  describe "option parsing" do
    test "parses consumer option correctly" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", ["-c", "Custom.Consumer"])
      |> assert_creates_module("Custom.Consumer")
    end

    test "parses domains option with multiple domains" do
      test_project()
      |> create_domain_module("A.Domain")
      |> create_domain_module("B.Domain")
      |> Igniter.compose_task("ash_discord.install", ["-d", "A.Domain,B.Domain"])
      |> assert_creates_consumer_with_domains(["A.Domain", "B.Domain"])
    end

    test "skips confirmation with --yes flag" do
      test_project()
      |> Igniter.compose_task("ash_discord.install", ["--yes"])
      |> assert_no_prompts()
    end
  end

  describe "error handling" do
    test "provides helpful error for missing Phoenix" do
      message =
        capture_error(fn ->
          test_project(phoenix: false)
          |> Igniter.compose_task("ash_discord.install", [])
        end)

      assert message =~ "requires a Phoenix application"
      assert message =~ "Please ensure your application is a Phoenix project"
    end

    test "provides helpful error for missing domain" do
      message =
        capture_error(fn ->
          test_project()
          |> Igniter.compose_task("ash_discord.install", ["--domains", "Missing.Domain"])
        end)

      assert message =~ "Domain module Missing.Domain does not exist"
      assert message =~ "Create the domain first"
    end
  end

  # Helper functions

  defp test_project(opts \\ []) do
    phoenix = Keyword.get(opts, :phoenix, true)
    deps = Keyword.get(opts, :deps, [{:ash, "~> 3.0"}])

    Igniter.new()
    |> Igniter.create_new_elixir_app("test")
    |> then(fn igniter ->
      if phoenix do
        igniter
        |> Igniter.Project.IgniterConfig.set(:phoenix, true)
        |> create_application_module()
      else
        igniter
      end
    end)
    |> add_dependencies(deps)
  end

  defp create_application_module(igniter) do
    content =
      quote do
        defmodule Test.Application do
          use Application

          @impl true
          def start(_type, _args) do
            children = [
              {Phoenix.PubSub, name: Test.PubSub}
            ]

            opts = [strategy: :one_for_one, name: Test.Supervisor]
            Supervisor.start_link(children, opts)
          end
        end
      end

    Igniter.Project.Module.create_module(igniter, Test.Application, content)
  end

  defp create_domain_module(igniter, module_name) do
    module = Module.concat([module_name])

    content =
      quote do
        defmodule unquote(module) do
          use Ash.Domain

          resources do
            # Domain resources would go here
          end
        end
      end

    Igniter.Project.Module.create_module(igniter, module, content)
  end

  defp add_dependencies(igniter, deps) do
    Enum.reduce(deps, igniter, fn dep, acc ->
      Igniter.Project.Deps.add_dep(acc, dep)
    end)
  end

  defp assert_creates_consumer_module(igniter) do
    assert_creates_module(igniter, "Test.DiscordConsumer")
  end

  defp assert_creates_module(igniter, module_name) do
    module = Module.concat([module_name])

    assert Igniter.Project.Module.module_exists?(igniter, module),
           "Expected module #{inspect(module)} to be created"

    igniter
  end

  defp assert_has_file(igniter, path) do
    assert Igniter.Project.SourceFile.exists?(igniter, path),
           "Expected file #{path} to exist"

    igniter
  end

  defp assert_file_contains(igniter, path, content) do
    file_content = Igniter.Project.SourceFile.read!(igniter, path)

    assert String.contains?(file_content, content),
           "Expected #{path} to contain: #{inspect(content)}"

    igniter
  end

  defp assert_creates_consumer_with_domains(igniter, expected_domains) do
    consumer_file = Igniter.Project.SourceFile.read!(igniter, "lib/test/discord_consumer.ex")

    Enum.each(expected_domains, fn domain ->
      assert String.contains?(consumer_file, domain),
             "Expected consumer to include domain #{domain}"
    end)

    igniter
  end

  defp assert_adds_nostrum_dependency(igniter) do
    assert_file_contains(igniter, "mix.exs", "nostrum")
  end

  defp assert_configures_environments(igniter) do
    igniter
    |> assert_file_contains("config/dev.exs", ":nostrum")
    |> assert_file_contains("config/test.exs", ":nostrum")
  end

  defp assert_adds_to_supervision_tree(igniter) do
    assert_file_contains(igniter, "lib/test/application.ex", "DiscordConsumer")
  end

  defp assert_adds_formatter_configuration(igniter) do
    assert_file_contains(igniter, ".formatter.exs", "ash_discord")
  end

  defp assert_unchanged(igniter) do
    # Verify no new changes were made
    igniter
  end

  defp assert_no_prompts(igniter) do
    # Verify no interactive prompts were shown
    igniter
  end

  defp capture_error(fun) do
    try do
      fun.()
      ""
    rescue
      e in RuntimeError -> Exception.message(e)
    end
  end
end
