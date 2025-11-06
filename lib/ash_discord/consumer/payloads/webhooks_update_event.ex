defmodule AshDiscord.Consumer.Payloads.WebhooksUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord WEBHOOKS_UPDATE event data.

  This event is an informational "ping" that indicates webhooks changed in a channel.
  It does NOT include which webhook changed or what action occurred - only that something
  changed. Applications must query the API to determine what actually changed.

  ## References
  - [Discord API - Webhooks Update Event](https://discord.com/developers/docs/topics/gateway-events#webhooks-update)
  - [GitHub Issue - WEBHOOKS_UPDATE limitations](https://github.com/discord/discord-api-docs/issues/1310)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "Guild ID where webhooks changed"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel ID where webhooks changed"
  end

  @doc """
  Create a WebhooksUpdateEvent TypedStruct from Discord event data.

  Accepts either a map with guild_id and channel_id fields, or an already-converted
  WebhooksUpdateEvent payload (idempotent operation).

  ## Examples

      iex> WebhooksUpdateEvent.new(%{guild_id: 123, channel_id: 456})
      {:ok, %WebhooksUpdateEvent{guild_id: 123, channel_id: 456}}

      iex> payload = %WebhooksUpdateEvent{guild_id: 123, channel_id: 456}
      iex> WebhooksUpdateEvent.new(payload)
      {:ok, %WebhooksUpdateEvent{guild_id: 123, channel_id: 456}}
  """
  def new(%__MODULE__{} = webhooks_update_payload) do
    {:ok, webhooks_update_payload}
  end

  def new(%{guild_id: guild_id, channel_id: channel_id})
      when is_integer(guild_id) and is_integer(channel_id) do
    super(%{guild_id: guild_id, channel_id: channel_id})
  end

  def new(%{"guild_id" => guild_id, "channel_id" => channel_id}) do
    super(%{guild_id: guild_id, channel_id: channel_id})
  end

  def new(data) when is_map(data) do
    # Try to extract fields from map with either atom or string keys
    guild_id = data[:guild_id] || data["guild_id"]
    channel_id = data[:channel_id] || data["channel_id"]

    if guild_id && channel_id do
      super(%{guild_id: guild_id, channel_id: channel_id})
    else
      {:error,
       "Invalid webhooks update event: missing guild_id or channel_id in #{inspect(data)}"}
    end
  end
end
