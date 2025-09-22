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
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    options = parse_and_validate_options(igniter)

    igniter
    |> add_dependencies()
    |> generate_consumer_module(options)
    |> setup_discord_configuration()
    |> add_consumer_to_supervision_tree(options)
    |> add_formatter_configuration()
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
    unless Igniter.Project.IgniterConfig.phoenix?(igniter) do
      raise """
      AshDiscord requires a Phoenix application.

      This installer is designed to work with Phoenix applications.
      Please ensure your application is a Phoenix project before running this installer.
      """
    end

    # Check for Ash framework presence
    deps = Igniter.Project.Deps.get_dependency_declaration(igniter, :ash)

    unless deps do
      raise """
      AshDiscord requires the Ash framework to be installed.

      Please add Ash to your dependencies first:
          {:ash, "~> 3.0"}

      Then run `mix deps.get` before running this installer again.
      """
    end
  end

  defp validate_domains!(igniter, domains) do
    # For each specified domain, validate it exists and uses Ash.Domain
    Enum.each(domains, fn domain_module ->
      case Igniter.Project.Module.module_exists?(igniter, domain_module) do
        false ->
          raise """
          Domain module #{inspect(domain_module)} does not exist.

          Please ensure all specified domains exist in your project before configuring them.
          Available options:
          - Create the domain first using `mix ash.gen.domain`
          - Remove this domain from the --domains option
          - Run the installer without --domains and configure them manually later
          """

        true ->
          # Verify it's actually an Ash domain
          # This validation will be enhanced once we can inspect the module content
          :ok
      end
    end)
  end

  # Helper functions for installer operations

  @doc false
  # Adds nostrum and ensures ash_discord runtime dependency
  defp add_dependencies(igniter) do
    igniter
    |> add_nostrum_dependency()
    |> ensure_ash_discord_runtime()
  end

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

  # Implementation helper functions

  defp add_nostrum_dependency(igniter) do
    Igniter.Project.Deps.add_dep(igniter, {:nostrum, "~> 0.10"})
  end

  defp ensure_ash_discord_runtime(igniter) do
    # Ensure ash_discord is available at runtime
    case Igniter.Project.Deps.get_dependency_declaration(igniter, :ash_discord) do
      nil ->
        # ash_discord should already be installed if this installer is running
        # but we'll add it if somehow it's not present
        Igniter.Project.Deps.add_dep(igniter, {:ash_discord, "~> 0.1"})

      _dep ->
        # ash_discord is already present
        igniter
    end
  end

  defp generate_consumer_module_content(igniter, consumer_module, domains) do
    domains_config =
      if domains == [] do
        # Empty list with helpful comment
        quote do
          # Add your Ash domains that should handle Discord interactions
          # Example: domains([MyApp.Discord, MyApp.Chat])
          domains([])
        end
      else
        # Configured domains list
        quote do
          domains(unquote(domains))
        end
      end

    module_content =
      quote do
        @moduledoc """
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
        """

        use AshDiscord.Consumer

        ash_discord_consumer do
          unquote(domains_config)
        end
      end

    Igniter.Project.Module.create_module(igniter, consumer_module, module_content)
  end

  defp setup_development_config(igniter) do
    Igniter.Project.Config.configure_new(
      igniter,
      "dev.exs",
      :nostrum,
      [:token],
      "your_dev_bot_token_here"
    )
  end

  defp setup_production_config(igniter) do
    runtime_config =
      quote do
        System.get_env("DISCORD_TOKEN") ||
          raise """
          Missing required environment variable: DISCORD_TOKEN

          Please set the DISCORD_TOKEN environment variable to your Discord bot token.
          You can get a bot token from https://discord.com/developers/applications
          """
      end

    Igniter.Project.Config.configure_runtime_env(
      igniter,
      :prod,
      :nostrum,
      [:token],
      {:code, runtime_config}
    )
  end

  defp setup_test_config(igniter) do
    # Test environment should not require a real Discord token
    Igniter.Project.Config.configure_new(
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
      consumer_module,
      after: fn children ->
        # Find PubSub position if it exists
        Enum.find_index(children, fn
          {Phoenix.PubSub, _} -> true
          module when is_atom(module) -> module == Phoenix.PubSub
          _ -> false
        end)
      end
    )
  end

  defp add_spark_formatter_plugin(igniter) do
    # Add Spark.Formatter plugin if not already present
    Igniter.Project.Formatter.add_formatter_plugin(igniter, Spark.Formatter)
  end
end
