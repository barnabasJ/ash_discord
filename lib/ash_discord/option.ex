defmodule AshDiscord.Option do
  @moduledoc """
  Represents a Discord slash command option (parameter).

  Options define the parameters that users can provide when invoking
  a Discord slash command.
  """

  defstruct [
    :name,
    :type,
    :description,
    :required,
    :choices
  ]

  @type option_type ::
          :string
          | :integer
          | :boolean
          | :user
          | :channel
          | :role
          | :mentionable
          | :number
          | :attachment

  @type choice :: %{
          name: String.t(),
          value: any()
        }

  @type t :: %__MODULE__{
          name: atom(),
          type: option_type(),
          description: String.t(),
          required: boolean(),
          choices: [choice()] | nil
        }
end
