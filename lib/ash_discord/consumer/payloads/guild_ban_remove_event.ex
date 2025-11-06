defmodule AshDiscord.Consumer.Payloads.GuildBanRemoveEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_BAN_REMOVE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.GuildBanRemove.t()`.

  ## References
  - [Discord API - Guild Ban Remove Event](https://discord.com/developers/docs/topics/gateway-events#guild-ban-remove)
  - [Nostrum - Event.GuildBanRemove](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildBanRemove.html)
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

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
