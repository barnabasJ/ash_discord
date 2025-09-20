defmodule AshDiscord.Dsl.Domain do
  @moduledoc """
  DSL entities and sections for Discord integration at the domain level.

  Provides the `discord do` block for Ash domains to define Discord slash commands.
  """

  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section
  alias AshDiscord.Command
  alias AshDiscord.Option

  @option %Entity{
    name: :option,
    target: Option,
    args: [:name, :type],
    describe: """
    Define a Discord slash command option (parameter).

    Options are automatically detected from the action's arguments and accepted attributes.
    You can manually define options to override the auto-detection or add custom options.
    """,
    examples: [
      "option :message, :string, required: true, description: \"Your message\"",
      "option :private, :boolean, required: false, description: \"Make conversation private\""
    ],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the option as it appears in Discord"
      ],
      type: [
        type:
          {:one_of,
           [
             :string,
             :integer,
             :boolean,
             :user,
             :channel,
             :role,
             :mentionable,
             :number,
             :attachment
           ]},
        required: true,
        doc: "The Discord option type"
      ],
      description: [
        type: :string,
        default: "",
        doc: "Description shown to users in Discord"
      ],
      required: [
        type: :boolean,
        default: false,
        doc: "Whether this option is required"
      ],
      choices: [
        type: {:list, :map},
        doc: "Predefined choices for the option"
      ]
    ]
  }

  @command %Entity{
    name: :command,
    target: Command,
    args: [:name, :resource, :action],
    entities: [
      options: [@option]
    ],
    describe: """
    Define a Discord slash command that maps to an Ash action.

    Commands defined here are automatically registered with Discord when the bot
    connects and are routed to the specified Ash resource action when invoked.
    """,
    examples: [
      """
      command :chat, MyApp.Chat.Conversation, :create do
        description "Start an AI conversation"
        option :message, :string, required: true, description: "Your message"
        option :private, :boolean, required: false, description: "Keep conversation private"
      end
      """,
      """
      command :help, MyApp.Support, :get_help do
        description "Get help with available commands"
        type :chat_input
        scope :guild
      end
      """,
      """
      command :weather, WeatherApp.Weather, :get_current do
        description "Get current weather for a location"
        formatter WeatherApp.Discord.WeatherFormatter
        option :location, :string, required: true, description: "City name"
      end
      """
    ],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The command name as it appears in Discord (without leading slash)"
      ],
      resource: [
        type: :atom,
        required: true,
        doc: "The Ash resource module that handles this command"
      ],
      action: [
        type: :atom,
        required: true,
        doc: "The Ash action to invoke when this command is used"
      ],
      description: [
        type: :string,
        default: "",
        doc: "Description shown to users in Discord"
      ],
      type: [
        type: {:one_of, [:chat_input, :user, :message]},
        default: :chat_input,
        doc: "Discord command type (slash command, user context menu, or message context menu)"
      ],
      scope: [
        type: {:one_of, [:guild, :global]},
        doc:
          "Command scope (guild commands are available instantly, global commands take time to propagate)"
      ],
      formatter: [
        type: :atom,
        doc:
          "Module that implements AshDiscord.ResponseFormatter behavior for custom response formatting. If not specified, AshDiscord.ResponseFormatter.Default is used."
      ]
    ]
  }

  @discord %Section{
    name: :discord,
    describe: """
    Configure Discord integration for this domain.

    Use this section to define Discord slash commands that map to Ash actions
    within the resources of this domain.
    """,
    examples: [
      """
      discord do
        command :chat, MyApp.Chat.Conversation, :create do
          description "Start an AI conversation"
          option :message, :string, required: true, description: "Your message"
        end
        
        command :history, MyApp.Chat.Conversation, :list do
          description "View your conversation history"
        end
      end
      """
    ],
    entities: [@command],
    schema: [
      default_scope: [
        type: {:one_of, [:guild, :global]},
        default: :guild,
        doc: "Default scope for commands defined in this domain"
      ],
      error_strategy: [
        type: {:one_of, [:user_friendly, :detailed, :silent]},
        default: :user_friendly,
        doc: "How to handle and display errors from Discord commands"
      ]
    ]
  }

  def discord, do: @discord
end
