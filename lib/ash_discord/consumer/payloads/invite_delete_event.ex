defmodule AshDiscord.Consumer.Payloads.InviteDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord INVITE_DELETE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.InviteDelete.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer, allow_nil?: false, description: "Channel ID of the channel"
    field :guild_id, :integer, description: "Guild ID of the guild"
    field :code, :string, allow_nil?: false, description: "Unique invite code"
  end

  @doc """
  Create an InviteDeleteEvent TypedStruct from a Nostrum InviteDelete event struct.

  Accepts a `Nostrum.Struct.Event.InviteDelete.t()` and creates an AshDiscord InviteDeleteEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.InviteDelete{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
