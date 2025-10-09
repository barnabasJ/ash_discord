defmodule AshDiscord.Consumer.Payloads.IntegrationDelete do
  @moduledoc """
  TypedStruct for Discord INTEGRATION_DELETE event payload.

  Contains the ID and guild ID of the deleted integration.

  ## References
  - [Discord API - Integration Delete Event](https://discord.com/developers/docs/topics/gateway-events#integration-delete)
  - [Nostrum - Event.GuildIntegrationDelete](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.GuildIntegrationDelete.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "ID of the integration"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "ID of the guild"

    field :application_id, :integer,
      allow_nil?: true,
      description: "ID of the bot/OAuth2 application for this Discord integration"
  end

  @doc """
  Create an IntegrationDelete TypedStruct from Nostrum IntegrationDelete event struct or return existing payload.
  """
  def new(%__MODULE__{} = event), do: {:ok, event}

  def new(%Nostrum.Struct.Event.GuildIntegrationDelete{} = event) do
    super(%{
      id: event.id,
      guild_id: event.guild_id,
      application_id: event.application_id
    })
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
