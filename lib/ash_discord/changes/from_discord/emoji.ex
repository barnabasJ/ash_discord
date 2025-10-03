defmodule AshDiscord.Changes.FromDiscord.Emoji do
  @moduledoc """
  Transforms Discord Emoji data into Ash resource attributes.

  Custom emojis belong to guilds and are not independently fetchable via simple ID,
  so only the `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Emoji.t()` or map with emoji data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Emoji

        change AshDiscord.Changes.FromDiscord.Emoji
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument(changeset, :data) do
        %Payloads.Emoji{} = emoji_data ->
          transform_emoji(changeset, emoji_data)

        data when is_map(data) ->
          # Accept raw map as well
          transform_emoji_from_map(changeset, data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "Emoji requires data argument - emojis require guild context to fetch from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Emoji{} or map, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_emoji(changeset, emoji_data) do
    # Determine if this is a custom emoji (has an ID)
    custom = if emoji_data.id, do: true, else: false

    changeset
    |> maybe_set_attribute(:discord_id, emoji_data.id)
    |> maybe_set_attribute(:name, emoji_data.name)
    |> maybe_set_attribute(:animated, emoji_data.animated || false)
    |> maybe_set_attribute(:custom, custom)
    |> maybe_set_attribute(:available, emoji_data.available)
    |> maybe_set_attribute(:require_colons, emoji_data.require_colons)
    |> maybe_set_attribute(:managed, emoji_data.managed)
    |> maybe_set_attribute(:roles, emoji_data.roles)
    |> maybe_manage_emoji_user_relationship(emoji_data.user)
  end

  defp transform_emoji_from_map(changeset, emoji_data) do
    # Determine if this is a custom emoji (has an ID)
    custom =
      case emoji_data[:id] || emoji_data["id"] do
        nil -> false
        _ -> true
      end

    changeset
    |> maybe_set_attribute(
      :discord_id,
      emoji_data[:id] || emoji_data["id"]
    )
    |> maybe_set_attribute(:name, emoji_data[:name] || emoji_data["name"])
    |> maybe_set_attribute(
      :animated,
      emoji_data[:animated] || emoji_data["animated"] || false
    )
    |> maybe_set_attribute(:custom, custom)
    |> maybe_set_attribute(:available, emoji_data[:available] || emoji_data["available"])
    |> maybe_set_attribute(
      :require_colons,
      emoji_data[:require_colons] || emoji_data["require_colons"]
    )
    |> maybe_set_attribute(:managed, emoji_data[:managed] || emoji_data["managed"])
    |> maybe_set_attribute(:roles, emoji_data[:roles] || emoji_data["roles"])
    |> maybe_manage_emoji_user_relationship(emoji_data[:user] || emoji_data["user"])
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  # Manage user relationship for emojis
  defp maybe_manage_emoji_user_relationship(changeset, %{id: user_id}) when not is_nil(user_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :user) do
      AshDiscord.Changes.FromDiscord.Transformations.manage_user_relationship(changeset, user_id)
    else
      changeset
    end
  end

  defp maybe_manage_emoji_user_relationship(changeset, user_map) when is_map(user_map) do
    user_id = user_map[:id] || user_map["id"]

    if user_id && Ash.Resource.Info.relationship(changeset.resource, :user) do
      AshDiscord.Changes.FromDiscord.Transformations.manage_user_relationship(changeset, user_id)
    else
      changeset
    end
  end

  defp maybe_manage_emoji_user_relationship(changeset, _), do: changeset
end
