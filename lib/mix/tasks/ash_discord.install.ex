if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshDiscord.Install do
    @moduledoc """
    Installs AshDiscord into a Phoenix application.

    Generates a Discord consumer, adds necessary dependencies, and configures
    the application for Discord bot integration using the AshDiscord framework.

    ## Usage

        mix ash_discord.install [--consumer NAME] [--domains LIST] [--yes]

    ## Options

      * `--consumer` (`-c`) - Name of the consumer module to generate
        (default: `AppName.DiscordConsumer`)
      * `--domains` (`-d`) - Comma-separated list of Ash domains to configure
        for Discord integration
      * `--yes` (`-y`) - Skip confirmation prompts

    ## Examples

        # Basic installation with default consumer
        mix ash_discord.install

        # Install with custom consumer name
        mix ash_discord.install --consumer MyApp.Bot.Consumer

        # Install with specific domains configured
        mix ash_discord.install --domains "MyApp.Discord,MyApp.Chat"

        # Install with all options
        mix ash_discord.install -c MyBot.Consumer -d "MyApp.Discord" -y

    This installer will:

    - Add the `:nostrum` dependency for Discord API interaction
    - Generate a Discord consumer module using `AshDiscord.Consumer`
    - Configure environment-specific Discord token management
    - Integrate the consumer into the application supervision tree
    - Set up Spark formatter configuration for proper DSL formatting

    After installation, you'll need to:

    1. Set your Discord bot token in `config/dev.exs` and environment variables
    2. Configure your Ash domains to handle Discord interactions
    3. Implement Discord commands and event handlers in your domains
    """

    use Igniter.Mix.Task

    alias Igniter.Project.{Config, Deps}
    alias Igniter.Project.Module, as: ProjectModule

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :ash,
        schema: [
          consumer: :string,
          domains: :string,
          yes: :boolean
        ],
        aliases: [
          c: :consumer,
          d: :domains,
          y: :yes
        ],
        installs: [{:ash, "~> 3.0"}],
        adds_deps: [{:nostrum, "~> 0.10"}]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = parse_and_validate_options(igniter)

      igniter
      |> generate_consumer_module(options)
      |> setup_discord_configuration()
      |> add_consumer_to_supervision_tree(options)
      |> add_formatter_configuration()
      |> add_installation_summary(options)
    end

    # Helper function for parsing and validating installer options
    defp parse_and_validate_options(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)

      # Extract options from igniter
      options = igniter.args.options

      # Process consumer option with default
      consumer =
        case options[:consumer] do
          nil ->
            # Default consumer name based on app name
            Module.concat([Macro.camelize(to_string(app_name)), "DiscordConsumer"])

          consumer_string ->
            # Parse provided consumer name
            Module.concat([consumer_string])
        end

      # Process domains option
      domains =
        case options[:domains] do
          nil ->
            []

          domains_string ->
            domains_string
            |> String.split(",", trim: true)
            |> Enum.map(&String.trim/1)
            |> Enum.map(&Module.concat([&1]))
        end

      # Validate project compatibility
      validate_project_compatibility!(igniter)

      # Validate specified domains if any were provided
      if domains != [] do
        validate_domains!(igniter, domains)
      end

      [
        consumer: consumer,
        domains: domains,
        yes: options[:yes] || false
      ]
    end

    defp validate_project_compatibility!(igniter) do
      # Check for Phoenix application structure
      # Note: We'll check for Phoenix by looking for Phoenix deps instead
      case Deps.get_dep(igniter, :phoenix) do
        {:error, _} ->
          raise """
          AshDiscord requires a Phoenix application.

          This installer is designed to work with Phoenix applications.
          Please ensure your application is a Phoenix project before running this installer.
          """

        {:ok, _} ->
          :ok
      end

      # Check for Ash framework presence
      case Deps.get_dep(igniter, :ash) do
        {:error, _} ->
          raise """
            AshDiscord requires the Ash framework to be installed.

          Please add Ash to your dependencies first:
              {:ash, "~> 3.0"}

          Then run `mix deps.get` before running this installer again.
          """

        {:ok, _} ->
          :ok
      end
    end

    defp validate_domains!(igniter, domains) do
      # For each specified domain, validate it exists and uses Ash.Domain
      Enum.each(domains, fn domain_module ->
        case ProjectModule.module_exists(igniter, domain_module) do
          {false, _igniter} ->
            raise """
            Domain module #{inspect(domain_module)} does not exist.

            Please ensure all specified domains exist in your project before configuring them.
            Available options:
            - Create the domain first using `mix ash.gen.domain`
            - Remove this domain from the --domains option
            - Run the installer without --domains and configure them manually later
            """

          {true, _igniter} ->
            # Verify it's actually an Ash domain
            # This validation will be enhanced once we can inspect the module content
            :ok
        end
      end)
    end

    # Helper functions for installer operations

    @doc false
    # Generates the Discord consumer module with DSL configuration
    defp generate_consumer_module(igniter, options) do
      consumer_module = options[:consumer]
      domains = options[:domains]

      generate_consumer_module_content(igniter, consumer_module, domains)
    end

    @doc false
    # Sets up Discord configuration across environments
    defp setup_discord_configuration(igniter) do
      igniter
      |> setup_development_config()
      |> setup_production_config()
      |> setup_test_config()
    end

    @doc false
    # Integrates consumer into application supervision tree
    defp add_consumer_to_supervision_tree(igniter, options) do
      consumer_module = options[:consumer]
      add_consumer_to_application(igniter, consumer_module)
    end

    @doc false
    # Adds Spark.Formatter configuration for DSL formatting
    defp add_formatter_configuration(igniter) do
      igniter
      |> Igniter.Project.Formatter.import_dep(:ash_discord)
      |> add_spark_formatter_plugin()
    end

    defp generate_consumer_module_content(igniter, consumer_module, domains) do
      domains_config =
        if domains == [] do
          """
          # Add your Ash domains that should handle Discord interactions
          # Example: domains([MyApp.Discord, MyApp.Chat])
          domains([])
          """
        else
          # Configured domains list
          domains_list = Enum.map_join(domains, ", ", &inspect/1)
          "domains([#{domains_list}])"
        end

      module_content = """
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
        #{domains_config}
      end
      """

      ProjectModule.create_module(igniter, consumer_module, module_content)
    end

    defp setup_development_config(igniter) do
      Config.configure_new(
        igniter,
        "dev.exs",
        :nostrum,
        [:token],
        "your_dev_bot_token_here"
      )
    end

    defp setup_production_config(igniter) do
      runtime_config = """
      System.get_env("DISCORD_TOKEN") ||
        raise \"\"\"
        Missing required environment variable: DISCORD_TOKEN

        Please set the DISCORD_TOKEN environment variable to your Discord bot token.
        You can get a bot token from https://discord.com/developers/applications
        \"\"\"
      """

      Config.configure_runtime_env(
        igniter,
        :prod,
        :nostrum,
        [:token],
        runtime_config
      )
    end

    defp setup_test_config(igniter) do
      # Test environment should not require a real Discord token
      Config.configure_new(
        igniter,
        "test.exs",
        :nostrum,
        [:token],
        "test_token_not_used"
      )
    end

    defp add_consumer_to_application(igniter, consumer_module) do
      # Add the consumer to the application supervision tree
      # Position it after PubSub if present, otherwise add at the end
      Igniter.Project.Application.add_new_child(
        igniter,
        consumer_module
      )
    end

    defp add_spark_formatter_plugin(igniter) do
      # Add Spark.Formatter plugin if not already present
      Igniter.Project.Formatter.add_formatter_plugin(igniter, Spark.Formatter)
    end

    defp add_installation_summary(igniter, options) do
      consumer_module = options[:consumer]
      domains = options[:domains]

      summary = generate_installation_summary(consumer_module, domains)

      Igniter.add_notice(igniter, summary)
    end

    defp generate_installation_summary(consumer_module, domains) do
      """

      🎉 AshDiscord Installation Complete!

      ✅ Consumer module created: #{inspect(consumer_module)}
      ✅ Dependencies added: nostrum (~> 0.10), ash_discord
      ✅ Discord configuration added for all environments
      ✅ Consumer integrated into application supervision tree
      ✅ Formatter configured for AshDiscord DSL

      📝 Next Steps:

      1. **Configure Your Discord Bot Token**

         Development (config/dev.exs):
         ```elixir
         config :nostrum,
           token: "your_dev_bot_token_here"
         ```

         Production (set environment variable):
         ```bash
         export DISCORD_TOKEN="your_production_bot_token"
         ```

         Get a bot token from: https://discord.com/developers/applications

      2. **Configure Ash Domains**#{domains_configuration_message(domains)}

      3. **Add Discord Commands**

         In your Ash domains, define Discord interactions:

         ```elixir
         defmodule MyApp.Discord do
           use Ash.Domain

           discord do
             command :ping do
               description "Responds with Pong!"

               execute fn interaction ->
                 {:ok, %{content: "Pong! 🏓"}}
               end
             end
           end
         end
         ```

      4. **Start Your Application**

         ```bash
         mix deps.get
         mix compile
         iex -S mix phx.server
         ```

         Your Discord bot will automatically connect and register commands!

      📚 Documentation:

      - AshDiscord Guide: https://hexdocs.pm/ash_discord
      - Nostrum Documentation: https://hexdocs.pm/nostrum
      - Discord Developer Portal: https://discord.com/developers/docs

      💡 Tips:

      - Use `mix ash_discord.gen.command` to generate new Discord commands
      - Check logs for Discord connection status and command registration
      - Test commands in a development Discord server first
      - Use Discord's application commands for better user experience

      🔧 Troubleshooting:

      If your bot doesn't connect:
      - Verify your bot token is correct
      - Check that the bot has been invited to your server
      - Ensure your bot has the necessary permissions
      - Review the logs for connection errors

      Happy Discord bot building! 🚀
      """
    end

    defp domains_configuration_message([]) do
      """

         Your consumer currently has no domains configured.
         Edit your consumer module and add domains to the DSL:

         ```elixir
         ash_discord_consumer do
           domains [MyApp.Discord, MyApp.Chat]
         end
         ```
      """
    end

    defp domains_configuration_message(domains) do
      """

         Your consumer is configured with these domains:
         #{Enum.map_join(domains, "\n       ", &"- #{inspect(&1)}")}

         You can add more domains by editing the consumer module.
      """
    end
  end
else
  defmodule Mix.Tasks.AshDiscord.Install do
    @moduledoc "Installs AshDiscord into a project. Should be called with `mix igniter.install ash_discord`"

    @shortdoc @moduledoc

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'ash_discord.install' requires igniter to be run.

      Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
