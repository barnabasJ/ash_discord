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
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case fetch_reaction_from_identity(identity) do
            {:ok, reaction_data} ->
              transform_message_reaction(changeset, reaction_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.MessageReactionAddEvent{} = reaction_data ->
          # Data provided directly, use it
          transform_message_reaction(changeset, reaction_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.MessageReactionAddEvent{}, got: #{inspect(other)}"
          )
      end
    end)
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
    # Handle emoji data
    emoji_data = reaction_data.emoji

    changeset
    |> maybe_set_attribute(:emoji_id, get_nested_id(emoji_data))
    |> maybe_set_attribute(:emoji_name, emoji_data && emoji_data.name)
    |> maybe_set_attribute(:emoji_animated, emoji_data && emoji_data.animated)
    |> maybe_set_attribute(:count, 1)
    |> maybe_set_attribute(:me, false)
    |> set_message_reaction_id_fields(reaction_data)
  end

  # Set all ID fields for message reactions
  defp set_message_reaction_id_fields(changeset, reaction_data) do
    changeset
    |> set_id_field(reaction_data, :user_id)
    |> set_id_field(reaction_data, :message_id)
    |> set_id_field(reaction_data, :channel_id)
    |> set_id_field(reaction_data, :guild_id)
  end

  defp set_id_field(changeset, data, field) do
    id_value = Map.get(data, field)

    if is_nil(id_value) do
      changeset
    else
      # Determine target field name based on what exists on the resource
      target_field = get_target_field_name(changeset.resource, field)

      if target_field do
        maybe_set_attribute(changeset, target_field, id_value)
      else
        changeset
      end
    end
  end

  # Helper to determine the correct field name based on resource structure
  defp get_target_field_name(resource, field) do
    # Convert :user_id -> :user_discord_id
    field_str = to_string(field)

    discord_field_name =
      field_str
      |> String.replace_suffix("_id", "_discord_id")
      |> String.to_atom()

    simple_field_name = field

    cond do
      Ash.Resource.Info.attribute(resource, discord_field_name) -> discord_field_name
      Ash.Resource.Info.attribute(resource, simple_field_name) -> simple_field_name
      true -> nil
    end
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
  defp get_nested_id(_), do: nil
end
