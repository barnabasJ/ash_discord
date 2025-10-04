defmodule AshDiscord.Changes.FromDiscord.Interaction do
  @moduledoc """
  Transforms Discord Interaction data into Ash resource attributes.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Interaction.t()` with Discord interaction data
  - `:identity` - Integer Discord interaction ID for API fallback (note: interactions are ephemeral)

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Interaction
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Interaction
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.Interaction{} = interaction_data ->
          transform_interaction(changeset, interaction_data)

        nil ->
          # Interactions are ephemeral and not fetchable from API
          Ash.Changeset.add_error(
            changeset,
            "Interactions cannot be fetched from API - data argument is required"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Interaction{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_interaction(changeset, interaction_data) do
    # Extract custom_id from data field
    custom_id =
      case interaction_data.data do
        %{custom_id: custom_id} -> custom_id
        _ -> nil
      end

    # Extract user ID from interaction (handles both guild and DM interactions)
    user_discord_id = get_interaction_user_id(interaction_data)

    changeset
    |> maybe_set_attribute(:discord_id, interaction_data.id)
    |> maybe_set_attribute(:type, interaction_data.type)
    |> maybe_set_attribute(:token, interaction_data.token)
    |> maybe_set_attribute(:application_id, interaction_data.application_id)
    |> maybe_set_attribute(:custom_id, custom_id)
    |> maybe_set_attribute(:data, interaction_data.data)
    |> maybe_set_attribute(:guild_id, interaction_data.guild_id)
    |> maybe_set_attribute(:channel_id, interaction_data.channel_id)
    |> maybe_set_attribute(:user_id, user_discord_id)
    |> maybe_set_attribute(:version, interaction_data.version)
    |> maybe_set_attribute(:locale, interaction_data.locale)
    |> maybe_set_attribute(:guild_locale, interaction_data.guild_locale)
    |> maybe_manage_guild_relationship(interaction_data.guild_id)
    |> maybe_manage_channel_relationship(interaction_data)
    |> maybe_manage_user_relationship(user_discord_id)
  end

  defp get_interaction_user_id(%{user: %{id: id}}), do: id
  defp get_interaction_user_id(%{member: %{user: %{id: id}}}), do: id
  defp get_interaction_user_id(_), do: nil

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
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

  defp maybe_manage_channel_relationship(changeset, %{channel_id: channel_id, guild_id: guild_id})
       when not is_nil(channel_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :channel) do
      Ash.Changeset.manage_relationship(
        changeset,
        :channel,
        %{discord_id: channel_id, guild_discord_id: guild_id},
        type: :append_and_remove,
        on_no_match: {:create, :from_discord}
      )
    else
      changeset
    end
  end

  defp maybe_manage_channel_relationship(changeset, _), do: changeset

  defp maybe_manage_user_relationship(changeset, nil), do: changeset

  defp maybe_manage_user_relationship(changeset, user_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :user) do
      Transformations.manage_user_relationship(changeset, user_discord_id)
    else
      changeset
    end
  end
end
