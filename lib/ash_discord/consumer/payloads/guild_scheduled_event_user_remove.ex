defmodule AshDiscord.Consumer.Payloads.GuildScheduledEventUserRemove do
  @moduledoc """
  TypedStruct for Discord GUILD_SCHEDULED_EVENT_USER_REMOVE event payload.

  Sent when a user has unsubscribed from a guild scheduled event.

  ## References
  - [Discord API - Guild Scheduled Event User Remove](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-user-remove)
  - [Nostrum - Event.GuildScheduledEventUserRemove](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildScheduledEventUserRemove.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_scheduled_event_id, :integer,
      allow_nil?: false,
      description: "The id of the guild scheduled event"

    field :user_id, :integer,
      allow_nil?: false,
      description: "The id of the user that unsubscribed"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "The id of the guild"
  end

  @doc """
  Create a GuildScheduledEventUserRemove TypedStruct from a Nostrum event struct.

  Accepts a `Nostrum.Struct.Event.GuildScheduledEventUserRemove.t()` and creates an AshDiscord GuildScheduledEventUserRemove TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildScheduledEventUserRemove{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
