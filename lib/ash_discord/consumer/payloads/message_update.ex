defmodule AshDiscord.Consumer.Payloads.MessageUpdate do
  @moduledoc """
  TypedStruct for Discord MESSAGE_UPDATE event payload.

  Contains old and new message data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_message, AshDiscord.Consumer.Payloads.Message,
      allow_nil?: true,
      description: "The previous message state (may be nil if not cached)"

    field :updated_message, AshDiscord.Consumer.Payloads.Message,
      allow_nil?: false,
      description: "The updated message state"
  end

  @doc """
  Create a MessageUpdate TypedStruct from Nostrum message update event data.

  Accepts a tuple `{old_message, updated_message}` where each is a `Nostrum.Struct.Message.t()`.
  """
  def new({old_message, %Nostrum.Struct.Message{} = updated_message}) do
    super(%{
      old_message: old_message && AshDiscord.Consumer.Payloads.Message.new(old_message),
      updated_message: AshDiscord.Consumer.Payloads.Message.new(updated_message)
    })
  end
end
