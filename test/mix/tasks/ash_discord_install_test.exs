defmodule Mix.Tasks.AshDiscord.InstallTest do
  use ExUnit.Case
  import Igniter.Test

  describe "ash_discord.install" do
    test "installs with default options" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_creates("lib/test/discord_consumer.ex")
      |> assert_has_patch("mix.exs", "{:nostrum, \"~> 0.10\"}")
      |> assert_has_patch("config/dev.exs", "config :nostrum")
      |> assert_has_patch(".formatter.exs", "ash_discord")
    end

    test "installs with custom consumer name" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", ["--consumer", "MyApp.Bot.Consumer"])
      |> assert_creates("lib/my_app/bot/consumer.ex")
    end

    test "installs with configured domains" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> create_domain_module("MyApp.Discord")
      |> create_domain_module("MyApp.Chat")
      |> Igniter.compose_task("ash_discord.install", ["--domains", "MyApp.Discord,MyApp.Chat"])
      |> assert_creates("lib/test/discord_consumer.ex")
      |> assert_has_patch("lib/test/discord_consumer.ex", "MyApp.Discord")
      |> assert_has_patch("lib/test/discord_consumer.ex", "MyApp.Chat")
    end

    test "fails without Phoenix application" do
      assert_raise RuntimeError, ~r/AshDiscord requires a Phoenix application/, fn ->
        test_project()
        |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
        |> Igniter.compose_task("ash_discord.install", [])
      end
    end

    test "fails without Ash framework" do
      assert_raise RuntimeError, ~r/AshDiscord requires the Ash framework/, fn ->
        test_project()
        |> setup_phoenix_project()
        |> Igniter.compose_task("ash_discord.install", [])
      end
    end

    test "validates domain existence" do
      assert_raise RuntimeError, ~r/Domain module.*does not exist/, fn ->
        test_project()
        |> setup_phoenix_project()
        |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
        |> Igniter.compose_task("ash_discord.install", ["--domains", "NonExistent.Domain"])
      end
    end

    test "consumer generation creates proper module structure" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("lib/test/discord_consumer.ex", "use AshDiscord.Consumer")
      |> assert_has_patch("lib/test/discord_consumer.ex", "ash_discord_consumer do")
      |> assert_has_patch("lib/test/discord_consumer.ex", "domains(")
    end

    test "dependency management adds nostrum" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("mix.exs", ~s|{:nostrum, "~> 0.10"}|)
    end

    test "environment configuration sets up all environments" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("config/dev.exs", "config :nostrum")
      |> assert_has_patch("config/runtime.exs", "DISCORD_TOKEN")
      |> assert_has_patch("config/test.exs", "config :nostrum")
    end

    test "supervision tree integration adds consumer" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("lib/test/application.ex", "Test.DiscordConsumer")
    end

    test "formatter configuration adds Spark.Formatter" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch(".formatter.exs", "ash_discord")
      |> assert_has_patch(".formatter.exs", "Spark.Formatter")
    end

    test "installer is idempotent" do
      project =
        test_project()
        |> setup_phoenix_project()
        |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
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
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", ["-c", "Custom.Consumer"])
      |> assert_creates("lib/custom/consumer.ex")
    end

    test "parses domains option with multiple domains" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> create_domain_module("A.Domain")
      |> create_domain_module("B.Domain")
      |> Igniter.compose_task("ash_discord.install", ["-d", "A.Domain,B.Domain"])
      |> assert_has_patch("lib/test/discord_consumer.ex", "A.Domain")
      |> assert_has_patch("lib/test/discord_consumer.ex", "B.Domain")
    end

    test "skips confirmation with --yes flag" do
      test_project()
      |> setup_phoenix_project()
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"})
      |> Igniter.compose_task("ash_discord.install", ["--yes"])
      |> assert_creates("lib/test/discord_consumer.ex")
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

  defp setup_phoenix_project(igniter) do
    igniter
    |> Igniter.Project.Deps.add_dep({:phoenix, "~> 1.7"})
    |> create_application_module()
    |> create_config_files()
  end

  defp create_config_files(igniter) do
    igniter
    |> Igniter.create_new_file("config/dev.exs", "import Config\n")
    |> Igniter.create_new_file("config/test.exs", "import Config\n")
    |> Igniter.create_new_file("config/runtime.exs", "import Config\n")
    |> Igniter.create_new_file(".formatter.exs", "[inputs: [\"*.{ex,exs}\"]]\n")
  end

  defp create_application_module(igniter) do
    content = """
    use Application

    @impl true
    def start(_type, _args) do
      children = [
        {Phoenix.PubSub, name: Test.PubSub}
      ]

      opts = [strategy: :one_for_one, name: Test.Supervisor]
      Supervisor.start_link(children, opts)
    end
    """

    Igniter.Project.Module.create_module(igniter, Test.Application, content)
  end

  defp create_domain_module(igniter, module_name) do
    module = Module.concat([module_name])

    content = """
    use Ash.Domain

    resources do
      # Domain resources would go here
    end
    """

    Igniter.Project.Module.create_module(igniter, module, content)
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
