defmodule AshDiscord.Consumer.Payloads.GuildBanRemoveEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_BAN_REMOVE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.GuildBanRemove.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, allow_nil?: false, description: "ID of the guild"

    field :user, AshDiscord.Consumer.Payloads.User,
      allow_nil?: false,
      description: "Unbanned user"
  end

  @doc """
  Create a GuildBanRemoveEvent TypedStruct from a Nostrum GuildBanRemove event struct.

  Accepts a `Nostrum.Struct.Event.GuildBanRemove.t()` and creates an AshDiscord GuildBanRemoveEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildBanRemove{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
