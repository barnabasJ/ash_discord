defmodule AshDiscord.Changes.FromDiscord.Webhook do
  @moduledoc """
  Transforms Discord Webhook data into Ash resource attributes.

  This change handles creating/updating Webhook resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Webhook.t()` with Discord webhook data
  - `:identity` - Integer Discord webhook ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Webhook
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Webhook
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.ApiFetchers
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case fetch_webhook(identity) do
            {:ok, %Payloads.Webhook{} = webhook_data} ->
              transform_webhook(changeset, webhook_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Webhook{} = webhook_data ->
          # Data provided directly, use it
          transform_webhook(changeset, webhook_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Webhook{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_webhook(discord_id) when is_integer(discord_id) do
    case Nostrum.Api.get_webhook(discord_id) do
      {:ok, webhook} -> {:ok, Payloads.Webhook.new(webhook)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_webhook(_), do: {:error, "Identity must be an integer Discord webhook ID"}

  defp transform_webhook(changeset, webhook_data) do
    changeset
    |> maybe_set_attribute(:discord_id, webhook_data.id)
    |> maybe_set_attribute(:name, webhook_data.name)
    |> maybe_set_attribute(:avatar, webhook_data.avatar)
    |> maybe_set_attribute(:token, webhook_data.token)
    |> maybe_set_attribute(:channel_discord_id, webhook_data.channel_id)
    |> maybe_set_attribute(:channel_id, webhook_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, webhook_data.guild_id)
    |> maybe_set_attribute(:guild_id, webhook_data.guild_id)
    |> maybe_set_attribute(:type, webhook_data.type)
    |> maybe_set_attribute(
      :source_guild_discord_id,
      get_nested_id(webhook_data.source_guild)
    )
    |> maybe_set_attribute(
      :source_channel_discord_id,
      get_nested_id(webhook_data.source_channel)
    )
    |> maybe_set_attribute(:user_discord_id, get_nested_id(webhook_data.user))
    |> maybe_set_attribute(:application_id, webhook_data.application_id)
    |> maybe_set_attribute(:url, webhook_data.url)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp get_nested_id(nil), do: nil
  defp get_nested_id(%{id: id}), do: id
  defp get_nested_id(map) when is_map(map), do: map[:id] || map["id"]
  defp get_nested_id(_), do: nil
end
