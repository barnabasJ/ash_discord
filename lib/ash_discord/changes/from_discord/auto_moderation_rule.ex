defmodule AshDiscord.Changes.FromDiscord.AutoModerationRule do
  @moduledoc """
  Transforms Discord AutoModerationRule data into Ash resource attributes.

  This change handles creating/updating AutoModerationRule resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.AutoModerationRule.t()` with auto mod rule data
  - `:identity` - Map with `%{guild_id: integer, rule_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.AutoModerationRule
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.AutoModerationRule
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      nil ->
        identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

        Ash.Changeset.before_transaction(changeset, fn changeset ->
          case fetch_auto_moderation_rule(identity) do
            {:ok, %Payloads.AutoModerationRule{} = rule_data} ->
              transform_auto_moderation_rule(changeset, rule_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end
        end)

      %Payloads.AutoModerationRule{} = rule_data ->
        transform_auto_moderation_rule(changeset, rule_data)

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected %AshDiscord.Consumer.Payloads.AutoModerationRule{}, got: #{inspect(other)}"
        )
    end
  end

  defp fetch_auto_moderation_rule(%{guild_discord_id: guild_id, discord_id: rule_id}) do
    case Nostrum.Api.AutoModeration.rule(guild_id, rule_id) do
      {:ok, rule} -> {:ok, Payloads.AutoModerationRule.new(rule)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    ArgumentError ->
      {:error, :api_unavailable}
  end

  defp fetch_auto_moderation_rule(_),
    do: {:error, "Identity must be a map with guild_id and rule_id"}

  defp transform_auto_moderation_rule(changeset, rule_data) do
    changeset
    |> maybe_set_attribute(:discord_id, rule_data.id)
    |> maybe_set_attribute(:name, rule_data.name)
    |> maybe_set_attribute(:event_type, rule_data.event_type)
    |> maybe_set_attribute(:trigger_type, rule_data.trigger_type)
    |> maybe_set_attribute(:trigger_metadata, rule_data.trigger_metadata)
    |> maybe_set_attribute(:actions, rule_data.actions)
    |> maybe_set_attribute(:enabled, rule_data.enabled)
    |> maybe_set_attribute(:exempt_roles, rule_data.exempt_roles)
    |> maybe_set_attribute(:exempt_channels, rule_data.exempt_channels)
    |> maybe_manage_guild_relationship(rule_data.guild_id)
    |> maybe_manage_creator_relationship(rule_data.creator_id)
  end

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_manage_creator_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :creator) do
      Transformations.manage_user_relationship(changeset, guild_discord_id, :creator)
    else
      changeset
    end
  end

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end
end
