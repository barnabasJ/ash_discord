defmodule AshDiscord.Changes.FromDiscord.MessageReaction do
  @moduledoc """
  Transforms Discord MessageReaction data into Ash resource attributes.

  This change handles creating/updating MessageReaction resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.MessageReactionAddEvent.t()` with reaction event data
  - `:identity` - Map with `%{channel_id: integer, message_id: integer, emoji_id: integer | nil, emoji_name: string, user_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.MessageReactionAddEvent
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.MessageReaction
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.ApiFetchers
  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    # First, extract and set attributes immediately (before validation)
    case Ash.Changeset.get_argument(changeset, :data) do
      nil ->
        # No data provided, will fetch from API in before_transaction
        Ash.Changeset.before_transaction(changeset, fn changeset ->
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case fetch_reaction_from_identity(identity) do
            {:ok, reaction_data} ->
              transform_message_reaction(changeset, reaction_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end
        end)

      data when is_map(data) ->
        # Data provided directly - set attributes immediately for validation
        transform_message_reaction(changeset, data)

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected map with reaction data, got: #{inspect(other)}"
        )
    end
  end

  defp fetch_reaction_from_identity(
         %{
           channel_id: channel_id,
           message_id: message_id,
           emoji_name: emoji_name,
           user_id: user_id
         } = identity
       )
       when not is_nil(channel_id) and not is_nil(message_id) and not is_nil(emoji_name) and
              not is_nil(user_id) do
    emoji_id = Map.get(identity, :emoji_id)

    # Fetch the message which includes reactions
    case ApiFetchers.fetch_message(%{channel_id: channel_id, message_id: message_id}) do
      {:ok, %Payloads.Message{} = message} ->
        # Find the matching reaction in the message
        reaction =
          Enum.find(message.reactions || [], fn r ->
            emoji_matches?(r.emoji, emoji_id, emoji_name)
          end)

        case reaction do
          nil ->
            {:error,
             "Reaction with emoji #{emoji_name} not found on message #{message_id} in channel #{channel_id}"}

          reaction_data ->
            # Convert to MessageReactionAddEvent format
            event_data = %Payloads.MessageReactionAddEvent{
              user_id: user_id,
              message_id: message_id,
              channel_id: channel_id,
              guild_id: message.guild_id,
              emoji: reaction_data.emoji
            }

            {:ok, event_data}
        end

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_reaction_from_identity(_),
    do:
      {:error,
       "MessageReaction requires identity with channel_id, message_id, emoji_name, and user_id for API fallback"}

  defp emoji_matches?(emoji, emoji_id, emoji_name) do
    # For custom emojis, match by ID
    if emoji_id do
      emoji.id == emoji_id
    else
      # For unicode emojis, match by name
      emoji.name == emoji_name
    end
  end

  defp transform_message_reaction(changeset, reaction_data) do
    # Handle emoji data - emoji is a plain map, not a struct
    emoji_data = reaction_data.emoji

    changeset
    |> maybe_set_attribute(:user_discord_id, reaction_data.user_id)
    |> maybe_set_attribute(:message_discord_id, reaction_data.message_id)
    |> maybe_set_attribute(:channel_discord_id, reaction_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, reaction_data.guild_id)
    |> maybe_set_attribute(:emoji_id, emoji_data && Map.get(emoji_data, :id))
    |> maybe_set_attribute(:emoji_name, emoji_data && Map.get(emoji_data, :name))
    |> maybe_set_attribute(:emoji_animated, emoji_data && Map.get(emoji_data, :animated, false))
    |> manage_relationships(reaction_data)
  end

  # Manage relationships for auto-creating related entities
  defp manage_relationships(changeset, reaction_data) do
    changeset
    |> Transformations.manage_user_relationship(reaction_data.user_id)
    |> Transformations.manage_message_relationship(reaction_data.message_id)
    |> Transformations.manage_channel_relationship(reaction_data.channel_id)
    |> Transformations.manage_guild_relationship(reaction_data.guild_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end
end
