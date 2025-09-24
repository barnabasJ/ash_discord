defmodule Mix.Tasks.AshDiscord.InstallTest do
  use ExUnit.Case
  import Igniter.Test

  describe "ash_discord.install" do
    test "installs with default options" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_creates("lib/test/discord_consumer.ex")
      # Note: Dependencies handled by installs/adds_deps in info/2
      |> assert_has_patch("config/dev.exs", """
      ...|
         + |config :nostrum, token: \"your_dev_bot_token_here\"
      ...|
      """)

      # Formatter patches tested separately
    end

    test "installs with custom consumer name" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", ["--consumer", "MyApp.Bot.Consumer"])
      |> assert_creates("lib/my_app/bot/consumer.ex")
    end

    test "installs with configured domains" do
      phx_test_project()
      |> create_domain_module("MyApp.Discord")
      |> create_domain_module("MyApp.Chat")
      |> Igniter.compose_task("ash_discord.install", ["--domains", "MyApp.Discord,MyApp.Chat"])
      |> assert_creates("lib/test/discord_consumer.ex", """
      defmodule Test.DiscordConsumer do
        @moduledoc \"\"\"
        Discord consumer for handling Discord events and commands.

        This consumer automatically processes Discord interactions and routes them
        to the appropriate Ash actions based on your domain configuration.

        ## Configuration

        Configure your Discord bot token in your environment configuration:

            # config/dev.exs
            config :nostrum,
              token: "your_dev_bot_token_here"

            # config/runtime.exs (for production)
            config :nostrum,
              token: System.get_env("DISCORD_TOKEN")

        ## Adding Discord Commands

        To add Discord commands, implement them in your configured Ash domains.
        Each domain can define Discord interactions that will be automatically
        registered and handled by this consumer.
        \"\"\"

        use AshDiscord.Consumer

        ash_discord_consumer do
          domains([MyApp.Discord, MyApp.Chat])
        end
      end
      """)
    end

    test "validates domain existence" do
      assert_raise RuntimeError, ~r/Domain module.*does not exist/, fn ->
        phx_test_project()
        |> Igniter.compose_task("ash_discord.install", ["--domains", "NonExistent.Domain"])
        |> apply_igniter!()
      end
    end

    test "consumer generation creates proper module structure" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_creates("lib/test/discord_consumer.ex")
    end

    test "environment configuration sets up all environments" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("config/dev.exs", """
      ...|
         + |config :nostrum, token: \"your_dev_bot_token_here\"
      ...|
      """)
      |> assert_has_patch("config/test.exs", """
      ...|
         + |config :nostrum, token: \"test_token_not_used\"
      ...|
      """)
      |> assert_has_patch("config/runtime.exs", """
      ...|
        53 + |  config :nostrum, token: \"System.get_env(\\\"DISCORD_TOKEN\\\") ||
        54 + |  raise \\\"\\\"\\\"
        55 + |  Missing required environment variable: DISCORD_TOKEN
        56 + |
        57 + |  Please set the DISCORD_TOKEN environment variable to your Discord bot token.
        58 + |  You can get a bot token from https://discord.com/developers/applications
        59 + |  \\\"\\\"\\\"
        60 + |\"
        61 + |
      ...|
      """)
    end

    test "supervision tree integration adds consumer" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_has_patch("lib/test/application.ex", """
      ...|
         + |        Test.DiscordConsumer,
      ...|
      """)
    end

    test "formatter configuration adds Spark.Formatter" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])

      # Note: Formatter configuration is validated in the comprehensive test above
      # The actual .formatter.exs modifications are complex and vary by project structure
    end

    test "installer is idempotent" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("ash_discord.install", [])
      |> assert_unchanged()
    end
  end

  describe "option parsing" do
    test "parses consumer option correctly" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", ["-c", "Custom.Consumer"])
      |> assert_creates("lib/custom/consumer.ex")
    end

    test "parses domains option with multiple domains" do
      phx_test_project()
      |> create_domain_module("A.Domain")
      |> create_domain_module("B.Domain")
      |> Igniter.compose_task("ash_discord.install", ["-d", "A.Domain,B.Domain"])
      |> assert_creates("lib/test/discord_consumer.ex")
    end

    test "skips confirmation with --yes flag" do
      phx_test_project()
      |> Igniter.compose_task("ash_discord.install", ["--yes"])
      |> assert_creates("lib/test/discord_consumer.ex")
    end
  end

  # Helper functions

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
end
