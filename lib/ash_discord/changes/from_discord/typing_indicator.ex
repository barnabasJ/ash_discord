defmodule AshDiscord.Changes.FromDiscord.TypingIndicator do
  @moduledoc """
  Transforms Discord TypingIndicator data into Ash resource attributes.

  Typing indicators are ephemeral events and not fetchable from API, so only the
  `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - Map with typing event data (user_id, channel_id, guild_id, timestamp)

  ## Example

      create :from_discord do
        argument :data, :map

        change AshDiscord.Changes.FromDiscord.TypingIndicator
      end
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        data when is_map(data) ->
          transform_typing_indicator(changeset, data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "TypingIndicator requires data argument - typing events are not fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected map, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_typing_indicator(changeset, typing_data) do
    changeset
    |> maybe_set_attribute(:user_discord_id, typing_data.user_id)
    |> maybe_set_attribute(:user_id, typing_data.user_id)
    |> maybe_set_attribute(:channel_discord_id, typing_data.channel_id)
    |> maybe_set_attribute(:channel_id, typing_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, typing_data.guild_id)
    |> maybe_set_attribute(:guild_id, typing_data.guild_id)
    |> set_typing_timestamp(typing_data)
    |> maybe_set_attribute(:member, typing_data.member)
  end

  # Handle timestamp setting for typing indicators
  defp set_typing_timestamp(changeset, %{timestamp: timestamp}) when not is_nil(timestamp) do
    parsed_timestamp = parse_timestamp(timestamp)
    maybe_set_attribute(changeset, :timestamp, parsed_timestamp)
  end

  defp set_typing_timestamp(changeset, data) when is_map(data) do
    case data["timestamp"] do
      nil ->
        # Default to current timestamp if none provided
        maybe_set_attribute(changeset, :timestamp, DateTime.utc_now())

      timestamp ->
        parsed_timestamp = parse_timestamp(timestamp)
        maybe_set_attribute(changeset, :timestamp, parsed_timestamp)
    end
  end

  defp set_typing_timestamp(changeset, _) do
    # Default to current timestamp if none provided
    maybe_set_attribute(changeset, :timestamp, DateTime.utc_now())
  end

  defp parse_timestamp(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp) do
      {:ok, dt} -> dt
      _ -> DateTime.utc_now()
    end
  end

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end

  defp parse_timestamp(%DateTime{} = dt), do: dt
  defp parse_timestamp(_), do: DateTime.utc_now()

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end
end
