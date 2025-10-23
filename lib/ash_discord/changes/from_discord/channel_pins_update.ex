defmodule AshDiscord.Changes.FromDiscord.ChannelPinsUpdate do
  @moduledoc """
  Transforms Discord ChannelPinsUpdate data into Ash resource attributes.

  This change handles creating/updating ChannelPinsUpdate resources from Discord data.
  Channel pins update events are informational and not fetchable from API, so only the
  `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent.t()` with Discord channel pins update data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent

        change AshDiscord.Changes.FromDiscord.ChannelPinsUpdate
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          Ash.Changeset.add_error(
            changeset,
            "ChannelPinsUpdate requires data argument - pins update events are not fetchable from API"
          )

        %Payloads.ChannelPinsUpdateEvent{} = pins_data ->
          transform_channel_pins_update(changeset, pins_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_channel_pins_update(changeset, pins_data) do
    changeset
    |> AshDiscord.Changes.FromDiscord.Transformations.manage_guild_relationship(
      pins_data.guild_id
    )
    |> AshDiscord.Changes.FromDiscord.Transformations.manage_channel_relationship(
      pins_data.channel_id
    )
    |> maybe_set_attribute(:last_pin_timestamp, pins_data.last_pin_timestamp)
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
end
