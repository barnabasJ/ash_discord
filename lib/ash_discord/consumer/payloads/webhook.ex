defmodule AshDiscord.Consumer.Payloads.Webhook do
  @moduledoc """
  TypedStruct wrapper for Discord Webhook data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Webhook.t()`,
  plus the `type` field from the Discord API.

  ## References
  - [Discord API - Webhook](https://discord.com/developers/docs/resources/webhook#webhook-object)
  - [Nostrum - Webhook](https://hexdocs.pm/nostrum/Nostrum.Struct.Webhook.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "The id of the webhook (snowflake)"

    field :type, :integer,
      description:
        "The type of the webhook (1 = Incoming, 2 = Channel Follower, 3 = Application) - not provided by Nostrum.Struct.Webhook"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "The guild id this webhook is for (snowflake), if available"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "The channel id this webhook is for (snowflake)"

    field :user, :map,
      allow_nil?: true,
      description:
        "The user this webhook was created by (not returned when getting a webhook with its token)"

    field :name, :string,
      allow_nil?: true,
      description: "The default name of the webhook"

    field :avatar, :string,
      allow_nil?: true,
      description: "The default avatar of the webhook (avatar hash)"

    field :token, :string,
      allow_nil?: true,
      description: "The secure token of the webhook (returned for Incoming Webhooks)"

    field :application_id, :integer,
      allow_nil?: true,
      description: "The bot/OAuth2 application that created this webhook (snowflake)"

    field :source_guild, :map,
      allow_nil?: true,
      description:
        "The guild of the channel that this webhook is following (partial guild object for Channel Follower Webhooks)"

    field :source_channel, :map,
      allow_nil?: true,
      description:
        "The channel that this webhook is following (partial channel object with id and name for Channel Follower Webhooks)"

    field :url, :string,
      allow_nil?: true,
      description: "The url used for executing the webhook (returned by the webhooks OAuth2 flow)"
  end

  @doc """
  Create a Webhook TypedStruct from a Nostrum Webhook struct.

  Accepts a `Nostrum.Struct.Webhook.t()` and creates an AshDiscord Webhook TypedStruct.
  Also handles being passed a Webhook payload (no-op for already-converted payloads) or a raw map for validation.

  Note: Nostrum.Struct.Webhook does not include the `type` field, so it will be nil when converting from Nostrum.
  """
  def new(%__MODULE__{} = webhook_payload) do
    {:ok, webhook_payload}
  end

  def new(%Nostrum.Struct.Webhook{} = nostrum_webhook) do
    super(Map.from_struct(nostrum_webhook))
  end

  def new(value) do
    super(value)
  end
end
