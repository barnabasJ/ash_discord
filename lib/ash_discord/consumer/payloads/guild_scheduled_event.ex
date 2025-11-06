defmodule AshDiscord.Consumer.Payloads.GuildScheduledEvent do
  @moduledoc """
  TypedStruct wrapper for Discord Guild Scheduled Event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.ScheduledEvent.t()`.

  ## References
  - [Discord API - Guild Scheduled Event](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object)
  - [Nostrum - Guild.ScheduledEvent](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.ScheduledEvent.html)
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "The id of the scheduled event"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "The guild id which the scheduled event belongs to"

    field :channel_id, :integer,
      allow_nil?: true,
      description:
        "The channel id in which the scheduled event will be hosted, or nil if entity_type is EXTERNAL"

    field :creator_id, :integer,
      allow_nil?: true,
      description:
        "The id of the user that created the scheduled event (nil for events created before October 25th, 2021)"

    field :name, :string,
      allow_nil?: false,
      description: "The name of the scheduled event"

    field :description, :string,
      allow_nil?: true,
      description: "The description of the scheduled event"

    field :scheduled_start_time, :utc_datetime,
      allow_nil?: false,
      description: "The time the scheduled event will start"

    field :scheduled_end_time, :utc_datetime,
      allow_nil?: true,
      description: "The time the scheduled event will end (required for EXTERNAL events)"

    field :privacy_level, :integer,
      allow_nil?: false,
      description: "The privacy level of the scheduled event (always 2 for GUILD_ONLY)"

    field :status, :integer,
      allow_nil?: false,
      description:
        "The status of the scheduled event (1=SCHEDULED, 2=ACTIVE, 3=COMPLETED, 4=CANCELLED)"

    field :entity_type, :integer,
      allow_nil?: false,
      description: "The type of the scheduled event (1=STAGE_INSTANCE, 2=VOICE, 3=EXTERNAL)"

    field :entity_id, :integer,
      allow_nil?: true,
      description: "The id of an entity associated with a guild scheduled event"

    field :entity_metadata, Payloads.GuildScheduledEventEntityMetadata,
      allow_nil?: true,
      description: "Additional metadata for the guild scheduled event"

    field :creator, Payloads.User,
      allow_nil?: true,
      description:
        "The user that created the scheduled event (nil for events created before October 25th, 2021)"

    field :user_count, :integer,
      allow_nil?: true,
      description: "The number of users subscribed to the scheduled event"
  end

  @doc """
  Create a GuildScheduledEvent TypedStruct from a Nostrum Guild.ScheduledEvent struct.

  Accepts a `Nostrum.Struct.Guild.ScheduledEvent.t()` and creates an AshDiscord GuildScheduledEvent TypedStruct.
  If already a GuildScheduledEvent payload, returns it as-is.
  """
  def new(%__MODULE__{} = event) do
    {:ok, event}
  end

  def new(%Nostrum.Struct.Guild.ScheduledEvent{} = nostrum_event) do
    super(%{
      id: nostrum_event.id,
      guild_id: nostrum_event.guild_id,
      channel_id: nostrum_event.channel_id,
      creator_id: nostrum_event.creator_id,
      name: nostrum_event.name,
      description: nostrum_event.description,
      scheduled_start_time: nostrum_event.scheduled_start_time,
      scheduled_end_time: nostrum_event.scheduled_end_time,
      privacy_level: nostrum_event.privacy_level,
      status: nostrum_event.status,
      entity_type: nostrum_event.entity_type,
      entity_id: nostrum_event.entity_id,
      entity_metadata:
        nostrum_event.entity_metadata &&
          transform_entity_metadata(nostrum_event.entity_metadata),
      creator: nostrum_event.creator && transform_user(nostrum_event.creator),
      user_count: nostrum_event.user_count
    })
  end

  defp transform_entity_metadata(%Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata{} = metadata) do
    case Payloads.GuildScheduledEventEntityMetadata.new(metadata) do
      {:ok, transformed} -> transformed
      _ -> nil
    end
  end

  defp transform_user(%Nostrum.Struct.User{} = user) do
    case Payloads.User.new(user) do
      {:ok, transformed} -> transformed
      _ -> nil
    end
  end
end
