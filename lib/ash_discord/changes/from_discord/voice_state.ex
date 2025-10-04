defmodule AshDiscord.Changes.FromDiscord.VoiceState do
  @moduledoc """
  Transforms Discord Voice State data into Ash resource attributes.

  Voice states are event-based and not independently fetchable from API,
  so only the `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.VoiceState.t()` with voice state data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.VoiceState

        change AshDiscord.Changes.FromDiscord.VoiceState
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.VoiceState{} = voice_state_data ->
          transform_voice_state(changeset, voice_state_data)

        %Payloads.VoiceStateEvent{} = voice_state_data ->
          # Also accept VoiceStateEvent for compatibility
          transform_voice_state(changeset, voice_state_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "VoiceState requires data argument - voice states are not independently fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.VoiceState{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_voice_state(changeset, voice_state_data) do
    changeset
    |> maybe_set_attribute(:user_discord_id, voice_state_data.user_id)
    |> maybe_set_attribute(:user_id, voice_state_data.user_id)
    |> maybe_set_attribute(:channel_discord_id, voice_state_data.channel_id)
    |> maybe_set_attribute(:channel_id, voice_state_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, voice_state_data.guild_id)
    |> maybe_set_attribute(:guild_id, voice_state_data.guild_id)
    |> maybe_set_attribute(:session_id, voice_state_data.session_id)
    |> maybe_set_attribute(:deaf, voice_state_data.deaf)
    |> maybe_set_attribute(:mute, voice_state_data.mute)
    |> maybe_set_attribute(:self_deaf, voice_state_data.self_deaf)
    |> maybe_set_attribute(:self_mute, voice_state_data.self_mute)
    |> maybe_set_attribute(:self_stream, voice_state_data.self_stream)
    |> maybe_set_attribute(:self_video, voice_state_data.self_video)
    |> maybe_set_attribute(:suppress, voice_state_data.suppress)
    |> maybe_set_datetime_field(
      :request_to_speak_timestamp,
      voice_state_data.request_to_speak_timestamp
    )
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_set_datetime_field(changeset, _field, nil), do: changeset

  defp maybe_set_datetime_field(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Transformations.set_datetime_field(changeset, field, value)
    else
      changeset
    end
  end
end
