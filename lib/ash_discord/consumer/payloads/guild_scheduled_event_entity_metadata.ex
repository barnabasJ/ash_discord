defmodule AshDiscord.Consumer.Payloads.GuildScheduledEventEntityMetadata do
  @moduledoc """
  TypedStruct wrapper for Discord Guild Scheduled Event Entity Metadata.

  Provides additional metadata associated with a scheduled event, such as location for external events.

  ## References
  - [Discord API - Guild Scheduled Event Entity Metadata](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-entity-metadata)
  - [Nostrum - Guild.ScheduledEvent.EntityMetadata](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :location, :string,
      allow_nil?: true,
      description: "Location of the event (1-100 characters, required for EXTERNAL events)"
  end

  @doc """
  Create an EntityMetadata TypedStruct from a Nostrum EntityMetadata struct.

  Accepts a `Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata.t()` and creates an AshDiscord EntityMetadata TypedStruct.
  If already an EntityMetadata payload, returns it as-is.
  """
  def new(%__MODULE__{} = metadata) do
    {:ok, metadata}
  end

  def new(%Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata{} = nostrum_metadata) do
    super(Map.from_struct(nostrum_metadata))
  end

  def new(nil), do: {:ok, nil}
end
