defmodule AshDiscord.Consumer.Payloads.VoiceServerUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SERVER_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceServerUpdate.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :token, :string, allow_nil?: false, description: "Voice connection token"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "Guild ID this voice server update is for"

    field :endpoint, :string, description: "Voice server host"
  end

  @doc """
  Create a VoiceServerUpdateEvent TypedStruct from a Nostrum VoiceServerUpdate event struct.

  Accepts a `Nostrum.Struct.Event.VoiceServerUpdate.t()` and creates an AshDiscord VoiceServerUpdateEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.VoiceServerUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
