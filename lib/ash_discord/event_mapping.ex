defmodule AshDiscord.EventMapping do
  @moduledoc """
  Represents a mapping from a Discord event to an Ash action.

  This struct is used as the target for the `on` entity in the `events do` section
  of the `ash_discord` DSL.

  ## Example

      events do
        on :MESSAGE_CREATE, :from_discord
        on :MESSAGE_DELETE, :soft_delete
      end
  """

  @type t :: %__MODULE__{
          event: atom(),
          action: atom()
        }

  defstruct [:event, :action]
end
