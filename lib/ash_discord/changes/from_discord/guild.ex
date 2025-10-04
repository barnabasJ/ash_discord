defmodule AshDiscord.Changes.FromDiscord.Guild do
  @moduledoc """
  Transforms Discord Guild data into Ash resource attributes.

  This change handles creating/updating Guild resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Guild.t()` with Discord guild data
  - `:identity` - Integer Discord guild ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Guild
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Guild
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.ApiFetchers
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case ApiFetchers.fetch_guild(identity) do
            {:ok, %Payloads.Guild{} = guild_data} ->
              transform_guild(changeset, guild_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Guild{} = guild_data ->
          # Data provided directly, use it
          transform_guild(changeset, guild_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Guild{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_guild(changeset, guild_data) do
    changeset
    |> maybe_set_attribute(:discord_id, guild_data.id)
    |> maybe_set_attribute(:name, guild_data.name)
    |> maybe_set_attribute(:description, guild_data.description)
    |> maybe_set_attribute(:icon, guild_data.icon)
    |> maybe_set_attribute(:owner_id, guild_data.owner_id)
    |> maybe_set_attribute(:member_count, guild_data.member_count)
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
