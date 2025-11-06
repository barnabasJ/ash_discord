defmodule AshDiscord.Changes.FromDiscord.Emoji do
  @moduledoc """
  Transforms Discord Emoji data into Ash resource attributes.

  This change handles creating/updating Emoji resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Emoji.t()` with emoji data
  - `:identity` - Map with `%{guild_id: integer, emoji_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Emoji
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.Emoji
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case fetch_emoji_from_identity(identity) do
            {:ok, %Payloads.Emoji{} = emoji_data} ->
              transform_emoji(changeset, emoji_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Emoji{} = emoji_data ->
          # Data provided directly, use it
          transform_emoji(changeset, emoji_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Emoji{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_emoji_from_identity(%{guild_id: guild_id, emoji_id: emoji_id}) do
    # Fetch emoji from guild
    case Nostrum.Api.Guild.emoji(guild_id, emoji_id) do
      {:ok, emoji} ->
        Payloads.Emoji.new(emoji)

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    ArgumentError ->
      {:error, :api_unavailable}
  end

  defp fetch_emoji_from_identity(_),
    do: {:error, "Identity must be a map with guild_id and emoji_id for API fallback"}

  defp transform_emoji(changeset, emoji_data) do
    # Determine if this is a custom emoji (has an ID)
    custom = if emoji_data.id, do: true, else: false

    # Get guild_id from identity argument if available
    guild_id =
      case Ash.Changeset.get_argument_or_attribute(changeset, :identity) do
        %{guild_id: guild_id} -> guild_id
        _ -> nil
      end

    changeset
    |> maybe_set_attribute(:discord_id, emoji_data.id)
    |> maybe_set_attribute(:name, emoji_data.name)
    |> maybe_set_attribute(:animated, emoji_data.animated || false)
    |> maybe_set_attribute(:custom, custom)
    |> maybe_set_attribute(:available, emoji_data.available)
    |> maybe_set_attribute(:require_colons, emoji_data.require_colons)
    |> maybe_set_attribute(:managed, emoji_data.managed)
    |> maybe_set_attribute(:roles, emoji_data.roles)
    |> maybe_manage_guild_relationship(guild_id)
    |> maybe_manage_emoji_user_relationship(emoji_data.user)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  # Manage guild relationship
  defp maybe_manage_guild_relationship(changeset, guild_id) when not is_nil(guild_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      AshDiscord.Changes.FromDiscord.Transformations.manage_guild_relationship(
        changeset,
        guild_id
      )
    else
      changeset
    end
  end

  defp maybe_manage_guild_relationship(changeset, _), do: changeset

  # Manage user relationship for emojis
  defp maybe_manage_emoji_user_relationship(changeset, %{id: user_id}) when not is_nil(user_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :user) do
      AshDiscord.Changes.FromDiscord.Transformations.manage_user_relationship(changeset, user_id)
    else
      changeset
    end
  end

  defp maybe_manage_emoji_user_relationship(changeset, _), do: changeset
end
