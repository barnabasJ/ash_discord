defmodule AshDiscord.Dsl.Consumer do
  @moduledoc """
  DSL entities and sections for consumer configuration.

  Provides the `ash_discord_consumer do` block for configuring AshDiscord consumers.
  Resources with the AshDiscord.Resource extension are automatically discovered from
  the configured domains.
  """

  alias Spark.Dsl.Section

  @ash_discord_consumer %Section{
    name: :ash_discord_consumer,
    describe: """
    Configure AshDiscord consumer behavior with automatic resource discovery.

    Resources with the AshDiscord.Resource extension are automatically discovered
    from the configured domains, eliminating the need for manual resource configuration.

    Simply specify your domains and the consumer will find all resources that handle
    Discord events.
    """,
    examples: [
      """
      # Simple configuration - resources auto-discovered from domains
      ash_discord_consumer do
        domains [MyApp.Discord]
      end
      """,
      """
      # With consumer-level options
      ash_discord_consumer do
        domains [MyApp.Chat, MyApp.Discord]
        store_bot_messages false
        debug_logging false
      end
      """
    ],
    schema: [
      domains: [
        type: {:list, :atom},
        required: true,
        doc: """
        List of Ash domains containing Discord commands and resources.

        Resources with the AshDiscord.Resource extension will be automatically
        discovered from these domains and used for Discord event handling.
        """
      ],
      command_filter: [
        type: :atom,
        doc:
          "Command filter module implementing AshDiscord.CommandFilter behavior for guild-scoped command filtering"
      ],
      store_bot_messages: [
        type: :boolean,
        default: false,
        doc: "Store messages from bot users"
      ],
      debug_logging: [
        type: :boolean,
        default: false,
        doc: "Enable debug logging for Discord events"
      ]
    ]
  }

  def ash_discord_consumer, do: @ash_discord_consumer
end
