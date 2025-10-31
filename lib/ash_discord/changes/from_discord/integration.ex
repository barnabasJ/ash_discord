defmodule AshDiscord.Changes.FromDiscord.Integration do
  @moduledoc """
  Transforms Discord Integration data into Ash resource attributes.

  This change handles creating/updating Integration resources from Discord data.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Integration.t()` with Discord integration data (required)

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Integration, allow_nil?: false

        change AshDiscord.Changes.FromDiscord.Integration
      end

  ## Note

  Unlike other from_discord implementations, Integration does not support API fallback since
  integrations can only be retrieved via guild-level API calls (`Nostrum.Api.Guild.integrations/1`).
  Therefore, this action does not accept an `identity` argument. The guild_id is obtained
  directly from the integration_data.guild_id field in the payload.
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided - integrations don't support API fallback
          Ash.Changeset.add_error(
            changeset,
            "Integration data is required - API fallback not supported for integrations"
          )

        %Payloads.Integration{} = integration_data ->
          # Data provided directly, use it
          transform_integration(changeset, integration_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Integration{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_integration(changeset, integration_data) do
    changeset
    |> maybe_set_attribute(:discord_id, integration_data.id)
    |> maybe_set_attribute(:name, integration_data.name)
    |> maybe_set_attribute(:type, integration_data.type)
    |> maybe_set_attribute(:enabled, integration_data.enabled)
    |> maybe_set_attribute(:account_discord_id, integration_data.account.id)
    |> maybe_set_attribute(:account_name, integration_data.account.name)
    |> maybe_set_attribute(
      :application_discord_id,
      integration_data.application && integration_data.application.id
    )
    |> maybe_set_attribute(
      :application_name,
      integration_data.application && integration_data.application.name
    )
    |> maybe_manage_guild_relationship(integration_data.guild_id)
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

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end
end
