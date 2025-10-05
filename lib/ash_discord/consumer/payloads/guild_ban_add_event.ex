defmodule AshDiscord.Consumer.Payloads.GuildBanAddEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_BAN_ADD event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.GuildBanAdd.t()`.

  ## References
  - [Discord API - Guild Ban Add Event](https://discord.com/developers/docs/topics/gateway-events#guild-ban-add)
  - [Nostrum - Event.GuildBanAdd](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildBanAdd.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, allow_nil?: false, description: "ID of the guild"

    field :user, AshDiscord.Consumer.Payloads.User,
      allow_nil?: false,
      description: "Banned user"
  end

  @doc """
  Create a GuildBanAddEvent TypedStruct from a Nostrum GuildBanAdd event struct.

  Accepts a `Nostrum.Struct.Event.GuildBanAdd.t()` and creates an AshDiscord GuildBanAddEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildBanAdd{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
