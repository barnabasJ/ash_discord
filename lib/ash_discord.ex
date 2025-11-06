defmodule AshDiscord do
  @moduledoc """
  AshDiscord extension for Ash domains and resources.

  This extension provides Discord slash command integration for Ash applications.
  It allows you to define Discord commands declaratively using a DSL and
  automatically handles command registration and interaction routing.

  ## Usage

  Add the extension to your Ash domain:

      defmodule MyApp.Chat do
        use Ash.Domain, extensions: [AshDiscord]

        discord do
          command :chat, MyApp.Chat.Conversation, :create do
            description "Start an AI conversation"
            option :message, :string, required: true, description: "Your message"
          end
        end
      end

  Commands defined in the DSL are automatically:
  - Registered with Discord when the bot connects
  - Routed to the specified Ash action when invoked
  - Validated at compile time

  ## Command Types

  - `:chat_input` - Standard slash commands (default)
  - `:user` - Right-click context menu on users
  - `:message` - Right-click context menu on messages

  ## Command Scope

  - `:guild` - Available immediately in specific guilds (default)
  - `:global` - Available everywhere but takes time to propagate
  """

  use Spark.Dsl.Extension,
    sections: [AshDiscord.Dsl.Domain.discord()],
    transformers: [
      AshDiscord.Transformers.ValidateCommands,
      AshDiscord.Transformers.AutoDetectOptions,
      AshDiscord.Transformers.EnhanceCommands
    ]

  @version Mix.Project.config()[:version]

  @doc """
  Returns the version of AshDiscord.
  """
  def version, do: @version
end
