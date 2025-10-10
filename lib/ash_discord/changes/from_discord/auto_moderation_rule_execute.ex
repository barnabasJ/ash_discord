defmodule AshDiscord.Changes.FromDiscord.AutoModerationRuleExecute do
  @moduledoc """
  Transforms Discord AutoModerationRuleExecute data into Ash resource attributes.

  This change handles creating AutoModerationRuleExecute records from Discord execution event data.
  This is an informational event with no API fallback - it only exists when Discord sends it.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.AutoModerationRuleExecute.t()` with execution event data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.AutoModerationRuleExecute

        change AshDiscord.Changes.FromDiscord.AutoModerationRuleExecute
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads
  alias AshDiscord.Changes.FromDiscord.Transformations

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      %Payloads.AutoModerationRuleExecute{} = event_data ->
        transform_execution_event(changeset, event_data)

      nil ->
        Ash.Changeset.add_error(changeset, "Missing required argument: data")

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected %AshDiscord.Consumer.Payloads.AutoModerationRuleExecute{}, got: #{inspect(other)}"
        )
    end
  end

  defp transform_execution_event(changeset, event_data) do
    changeset
    |> maybe_set_attribute(:action, event_data.action)
    |> maybe_set_attribute(:rule_trigger_type, event_data.rule_trigger_type)
    |> maybe_set_attribute(:alert_system_message_id, event_data.alert_system_message_id)
    |> maybe_set_attribute(:content, event_data.content)
    |> maybe_set_attribute(:matched_keyword, event_data.matched_keyword)
    |> maybe_set_attribute(:matched_content, event_data.matched_content)
    |> maybe_manage_user_relationship(event_data.user_id)
    |> maybe_manage_guild_relationship(event_data.guild_id)
    |> maybe_manage_rule_relationship(event_data.rule_id)
    |> maybe_manage_channel_relationship(event_data.channel_id)
    |> maybe_manage_message_relationship(event_data.message_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_manage_user_relationship(changeset, nil), do: changeset

  defp maybe_manage_user_relationship(changeset, user_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :user) do
      Transformations.manage_user_relationship(changeset, user_discord_id)
    else
      changeset
    end
  end

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end

  defp maybe_manage_rule_relationship(changeset, nil), do: changeset

  defp maybe_manage_rule_relationship(changeset, rule_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :rule) do
      Transformations.manage_rule_relationship(changeset, rule_discord_id)
    else
      changeset
    end
  end

  defp maybe_manage_channel_relationship(changeset, nil), do: changeset

  defp maybe_manage_channel_relationship(changeset, channel_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :channel) do
      Transformations.manage_channel_relationship(changeset, channel_discord_id)
    else
      changeset
    end
  end

  defp maybe_manage_message_relationship(changeset, nil), do: changeset

  defp maybe_manage_message_relationship(changeset, message_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :message) do
      Transformations.manage_message_relationship(changeset, message_discord_id)
    else
      changeset
    end
  end
end
