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
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case fetch_auto_moderation_rule(identity) do
            {:ok, %Payloads.AutoModerationRule{} = rule_data} ->
              transform_auto_moderation_rule(changeset, rule_data, identity)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.AutoModerationRule{} = rule_data ->
          # Data provided directly, use it
          identity = Ash.Changeset.get_argument(changeset, :identity)
          transform_auto_moderation_rule(changeset, rule_data, identity)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.AutoModerationRule{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_auto_moderation_rule(%{guild_id: guild_id, rule_id: rule_id}) do
    case Nostrum.Api.get_auto_moderation_rule(guild_id, rule_id) do
      {:ok, rule} -> {:ok, Payloads.AutoModerationRule.new(rule)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_auto_moderation_rule(_),
    do: {:error, "Identity must be a map with guild_id and rule_id"}

  defp transform_auto_moderation_rule(changeset, rule_data, identity) do
    guild_discord_id =
      (identity && (identity[:guild_id] || identity["guild_id"])) || rule_data.guild_id

    changeset
    |> maybe_set_attribute(:discord_id, rule_data.id)
    |> maybe_set_attribute(:guild_discord_id, guild_discord_id)
    |> maybe_set_attribute(:guild_id, guild_discord_id)
    |> maybe_set_attribute(:name, rule_data.name)
    |> maybe_set_attribute(:creator_id, rule_data.creator_id)
    |> maybe_set_attribute(:event_type, rule_data.event_type)
    |> maybe_set_attribute(:trigger_type, rule_data.trigger_type)
    |> maybe_set_attribute(:trigger_metadata, rule_data.trigger_metadata)
    |> maybe_set_attribute(:actions, rule_data.actions)
    |> maybe_set_attribute(:enabled, rule_data.enabled)
    |> maybe_set_attribute(:exempt_roles, rule_data.exempt_roles)
    |> maybe_set_attribute(:exempt_channels, rule_data.exempt_channels)
    |> maybe_manage_guild_relationship(guild_discord_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
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
end
