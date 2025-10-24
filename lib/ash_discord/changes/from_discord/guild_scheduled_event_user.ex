defmodule AshDiscord.Changes.FromDiscord.GuildScheduledEventUser do
  @moduledoc """
  Transforms Discord GuildScheduledEventUser data into Ash resource attributes.

  This change handles creating/updating GuildScheduledEventUser resources from Discord data.
  Tracks user subscriptions to guild scheduled events.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.GuildScheduledEventUserAdd.t()` with event user data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.GuildScheduledEventUserAdd

        change AshDiscord.Changes.FromDiscord.GuildScheduledEventUser
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.GuildScheduledEventUserAdd{} = event_user_data ->
          transform_event_user(changeset, event_user_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "GuildScheduledEventUser requires data argument"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.GuildScheduledEventUserAdd{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_event_user(changeset, event_user_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(
      :event_discord_id,
      event_user_data.guild_scheduled_event_id
    )
    |> Ash.Changeset.force_change_attribute(:user_discord_id, event_user_data.user_id)
    |> Ash.Changeset.force_change_attribute(:guild_discord_id, event_user_data.guild_id)
  end
end
