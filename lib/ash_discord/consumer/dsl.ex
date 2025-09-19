defmodule AshDiscord.Consumer.Dsl do
  @moduledoc """
  A consumer allows you to define Discord bot behavior with DSL configuration.

  For example:

  ```elixir
  defmodule MyApp.DiscordConsumer do
    use AshDiscord.Consumer.Dsl

    ash_discord_consumer do
      domains [MyApp.Chat, MyApp.Discord]
      guild_resource MyApp.Discord.Guild
      message_resource MyApp.Discord.Message  
      user_resource MyApp.Accounts.User
      auto_create_users true
    end

    # Override callbacks as needed
    def handle_message_create(message) do
      # Custom message handling
      :ok
    end
  end
  ```
  """

  @doc false
  @callback consumer?() :: true

  use Spark.Dsl,
    default_extensions: [extensions: [AshDiscord.ConsumerExtension]],
    opt_schema: [
      domains: [
        type: {:list, :atom},
        default: [],
        doc: "Legacy domains option for backward compatibility"
      ],
      command_filter: [
        type: :atom,
        doc: "Legacy command filter option for backward compatibility"
      ]
    ]

  require Ash.Query

  @type t() :: module

  @impl Spark.Dsl
  def handle_opts(opts) do
    domains = Keyword.get(opts, :domains, [])
    command_filter = Keyword.get(opts, :command_filter, nil)

    quote do
      @behaviour AshDiscord.Consumer.Dsl

      @impl AshDiscord.Consumer.Dsl
      def consumer?, do: true

      require Logger

      @ash_discord_domains unquote(domains)
      @ash_discord_command_filter unquote(command_filter)
      
      # Commands built from DSL domains at runtime, not compile-time
      defp get_commands do
        domains = AshDiscord.Consumer.Info.ash_discord_consumer_domains!(__MODULE__)
        AshDiscord.Consumer.collect_commands(domains)
      end
      
      # DSL configuration will be accessed at runtime via generated Info functions

      @doc "Returns the configured domains for this consumer"
      def domains do
        AshDiscord.Consumer.Info.ash_discord_consumer_domains!(__MODULE__)
      end

      @doc "Returns the configured command filter for this consumer"
      def command_filter do
        AshDiscord.Consumer.Info.ash_discord_consumer_command_filter!(__MODULE__)
      end

      @doc "Finds a command by name from the DSL domains"
      def find_command(command_name) do
        commands = get_commands()
        Enum.find(commands, fn cmd -> cmd.name == command_name end)
      end
    end
  end

  @impl Spark.Dsl
  def explain(dsl_state, _opts) do
    Spark.Dsl.Transformer.get_entities(dsl_state, [:ash_discord_consumer])
  end
end