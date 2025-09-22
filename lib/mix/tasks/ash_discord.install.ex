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

  defp add_dependencies(igniter) do
    # TODO: Implement dependency management
    igniter
  end

  defp generate_consumer_module(igniter, _options) do
    # TODO: Implement consumer module generation
    igniter
  end

  defp setup_discord_configuration(igniter) do
    # TODO: Implement Discord configuration setup
    igniter
  end

  defp add_consumer_to_supervision_tree(igniter, _options) do
    # TODO: Implement supervision tree integration
    igniter
  end

  defp add_formatter_configuration(igniter) do
    # TODO: Implement formatter configuration
    igniter
  end
end
