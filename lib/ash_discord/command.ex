defmodule AshDiscord.Command do
  @moduledoc """
  Represents a Discord slash command definition.

  This struct holds all the information needed to register and handle
  a Discord slash command, including its metadata, options, and routing
  information to Ash actions.
  """

  defstruct [
    :name,
    :resource,
    :action,
    :description,
    :type,
    :scope,
    :options,
    :domain,
    :formatter
  ]

  @type command_type :: :chat_input | :user | :message
  @type command_scope :: :guild | :global

  @type option :: %{
          name: atom(),
          type:
            :string
            | :integer
            | :boolean
            | :user
            | :channel
            | :role
            | :mentionable
            | :number
            | :attachment,
          description: String.t(),
          required: boolean(),
          choices: list() | nil
        }

  @type t :: %__MODULE__{
          name: atom(),
          resource: module(),
          action: atom(),
          description: String.t(),
          type: command_type(),
          scope: command_scope(),
          options: [option()],
          domain: module(),
          formatter: module() | nil
        }
end
