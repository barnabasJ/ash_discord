defmodule AshDiscord.Consumer.Payloads.GuildIntegrationDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_INTEGRATION_DELETE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.GuildIntegrationDelete.t()`.

  ## References
  - [Discord API - Guild Integration Delete Event](https://discord.com/developers/docs/topics/gateway-events#guild-integration-delete)
  - [Nostrum - Event.GuildIntegrationDelete](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildIntegrationDelete.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The id of the deleted integration"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "The id of the guild the integration is in"

    field :application_id, :integer,
      description: "id of the bot/OAuth2 application for this discord integration"
  end

  @doc """
  Create a GuildIntegrationDeleteEvent TypedStruct from a Nostrum GuildIntegrationDelete event struct.

  Accepts a `Nostrum.Struct.Event.GuildIntegrationDelete.t()` and creates an AshDiscord GuildIntegrationDeleteEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildIntegrationDelete{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
