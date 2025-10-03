defmodule AshDiscord.Changes.FromDiscord.Message do
  @moduledoc """
  Transforms Discord Message data into Ash resource attributes.

  This change handles creating/updating Message resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Message.t()` with Discord message data
  - `:identity` - Map with `%{channel_id: integer, message_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Message
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.Message
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case ApiFetchers.fetch_message(identity) do
            {:ok, %Payloads.Message{} = message_data} ->
              transform_message(changeset, message_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Message{} = message_data ->
          # Data provided directly, use it
          transform_message(changeset, message_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Message{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_message(changeset, message_data) do
    changeset
    |> maybe_set_attribute(:discord_id, message_data.id)
    |> maybe_set_attribute(:content, message_data.content || "")
    |> maybe_set_attribute(:embeds, message_data.embeds)
    |> conditionally_set_datetime_field(:timestamp, message_data.timestamp)
    |> conditionally_set_datetime_field(:edited_timestamp, message_data.edited_timestamp)
    |> maybe_set_attribute(:tts, message_data.tts)
    |> maybe_set_attribute(:mention_everyone, message_data.mention_everyone)
    |> maybe_set_attribute(:pinned, message_data.pinned)
    |> maybe_manage_guild_relationship(message_data.guild_id)
    |> maybe_manage_channel_relationship(message_data.channel_id)
    |> maybe_manage_author_relationship(message_data.author)
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

  defp conditionally_set_datetime_field(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Transformations.set_datetime_field(changeset, field, value)
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

  defp maybe_manage_channel_relationship(changeset, nil), do: changeset

  defp maybe_manage_channel_relationship(changeset, channel_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :channel) do
      Transformations.manage_channel_relationship(changeset, channel_id)
    else
      changeset
    end
  end

  defp maybe_manage_author_relationship(changeset, nil), do: changeset

  defp maybe_manage_author_relationship(changeset, %{id: author_id}) when is_integer(author_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :author) do
      Transformations.manage_user_relationship(changeset, author_id, :author)
    else
      changeset
    end
  end

  defp maybe_manage_author_relationship(changeset, _), do: changeset
end
