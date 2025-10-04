defmodule AshDiscord.Consumer.Payloads.Webhook do
  @moduledoc """
  TypedStruct wrapper for Discord Webhook data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Webhook.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "Webhook id"
    field :name, :string, description: "Webhook name"
    field :avatar, :string, description: "Webhook avatar hash"
    field :token, :string, description: "Secure token for the webhook"
    field :channel_id, :integer, description: "Channel id this webhook is for"
    field :guild_id, :integer, description: "Guild id this webhook is for"
    field :type, :integer, description: "Type of webhook"

    field :source_guild, :map,
      description: "Partial guild object for webhooks created from server following"

    field :source_channel, :map,
      description: "Partial channel object for webhooks created from server following"

    field :user, :map, description: "User object of the webhook creator"
    field :application_id, :integer, description: "Bot/OAuth2 application id"
    field :url, :string, description: "URL for executing the webhook"
  end

  @doc """
  Create a Webhook TypedStruct from a Nostrum Webhook struct.

  Accepts a `Nostrum.Struct.Webhook.t()` and creates an AshDiscord Webhook TypedStruct.
  Also handles being passed a Webhook payload (no-op for already-converted payloads) or a raw map for validation.
  """
  def new(%__MODULE__{} = webhook_payload) do
    {:ok, webhook_payload}
  end

  def new(%Nostrum.Struct.Webhook{} = nostrum_webhook) do
    super(Map.from_struct(nostrum_webhook))
  end
end
