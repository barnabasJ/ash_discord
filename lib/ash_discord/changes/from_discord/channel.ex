defmodule AshDiscord.Changes.FromDiscord.Channel do
  @moduledoc """
  Transforms Discord Channel data into Ash resource attributes.

  This change handles creating/updating Channel resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Channel.t()` with Discord channel data
  - `:identity` - Integer Discord channel ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Channel
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Channel
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case ApiFetchers.fetch_channel(identity) do
            {:ok, %Payloads.Channel{} = channel_data} ->
              transform_channel(changeset, channel_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Channel{} = channel_data ->
          # Data provided directly, use it
          transform_channel(changeset, channel_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Channel{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_channel(changeset, channel_data) do
    changeset
    |> maybe_set_attribute(:discord_id, channel_data.id)
    |> maybe_set_attribute(:name, channel_data.name)
    |> maybe_set_attribute(:type, channel_data.type)
    |> maybe_set_attribute(:position, channel_data.position)
    |> maybe_set_attribute(:topic, channel_data.topic)
    |> maybe_set_attribute(:nsfw, channel_data.nsfw)
    |> maybe_set_attribute(:parent_id, channel_data.parent_id)
    |> maybe_set_attribute(
      :permission_overwrites,
      Transformations.transform_permission_overwrites(channel_data.permission_overwrites)
    )
    |> maybe_manage_guild_relationship(channel_data.guild_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_id)
    else
      changeset
    end
  end
end
