defmodule AshDiscord.Consumer.Payloads.GuildScheduledEventUserAdd do
  @moduledoc """
  TypedStruct for Discord GUILD_SCHEDULED_EVENT_USER_ADD event payload.

  Sent when a user has subscribed to a guild scheduled event.

  ## References
  - [Discord API - Guild Scheduled Event User Add](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-user-add)
  - [Nostrum - Event.GuildScheduledEventUserAdd](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildScheduledEventUserAdd.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_scheduled_event_id, :integer,
      allow_nil?: false,
      description: "The id of the guild scheduled event"

    field :user_id, :integer,
      allow_nil?: false,
      description: "The id of the user that subscribed"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "The id of the guild"
  end

  @doc """
  Create a GuildScheduledEventUserAdd TypedStruct from a Nostrum event struct.

  Accepts a `Nostrum.Struct.Event.GuildScheduledEventUserAdd.t()` and creates an AshDiscord GuildScheduledEventUserAdd TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildScheduledEventUserAdd{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
