defmodule AshDiscord.Consumer.Payloads.MessageUpdate do
  @moduledoc """
  TypedStruct for Discord MESSAGE_UPDATE event payload.

  Contains old and new message data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Message

  typed_struct do
    field :old_message, Message,
      allow_nil?: true,
      description: "The previous message state (may be nil if not cached)"

    field :updated_message, Message,
      allow_nil?: false,
      description: "The updated message state"
  end
end
