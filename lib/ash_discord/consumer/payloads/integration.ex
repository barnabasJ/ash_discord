defmodule AshDiscord.Consumer.Payloads.Integration do
  @moduledoc """
  TypedStruct for Discord Integration.

  Represents a guild integration (Twitch, YouTube, Discord, etc.).

  ## References
  - [Discord API - Integration Object](https://discord.com/developers/docs/resources/guild#integration-object)
  - [Nostrum - Guild.Integration](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Integration.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "Integration ID"

    field :name, :string,
      allow_nil?: false,
      description: "Integration name"

    field :type, :string,
      allow_nil?: false,
      description: "Integration type (twitch, youtube, discord, etc.)"

    field :enabled, :boolean,
      allow_nil?: false,
      description: "Whether this integration is enabled"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "ID of the guild (only included in gateway events)"

    field :account, AshDiscord.Consumer.Payloads.IntegrationAccount,
      allow_nil?: false,
      description: "Integration account information"

    field :application, AshDiscord.Consumer.Payloads.IntegrationApplication,
      allow_nil?: true,
      description: "Bot/OAuth2 application for Discord integrations"
  end

  @doc """
  Create an Integration TypedStruct from Nostrum Integration struct or return existing payload.
  """
  def new(%__MODULE__{} = integration), do: {:ok, integration}

  def new(%Nostrum.Struct.Guild.Integration{} = integration) do
    super(%{
      id: integration.id,
      name: integration.name,
      type: integration.type,
      enabled: integration.enabled,
      guild_id: integration.guild_id,
      account: integration.account,
      application: integration.application
    })
  end
end
