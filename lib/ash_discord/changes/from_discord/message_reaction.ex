defmodule AshDiscord.Changes.FromDiscord.MessageReaction do
  @moduledoc """
  Transforms Discord MessageReaction data into Ash resource attributes.

  Message reactions are event-based and not fetchable from API, so only the
  `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.MessageReactionAddEvent.t()` with reaction event data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.MessageReactionAddEvent

        change AshDiscord.Changes.FromDiscord.MessageReaction
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.MessageReactionAddEvent{} = reaction_data ->
          transform_message_reaction(changeset, reaction_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "MessageReaction requires data argument - reactions are not fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.MessageReactionAddEvent{}, got: #{inspect(other)}"
          )
      end
    end)
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
