defmodule AshDiscord.Changes.FromDiscord.Sticker do
  @moduledoc """
  Transforms Discord Sticker data into Ash resource attributes.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Sticker.t()` with Discord sticker data
  - `:identity` - Integer Discord sticker ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Sticker
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Sticker
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.ApiFetchers
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case ApiFetchers.fetch_from_nostrum_api(:sticker, identity) do
            {:ok, %Payloads.Sticker{} = sticker_data} ->
              transform_sticker(changeset, sticker_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Sticker{} = sticker_data ->
          transform_sticker(changeset, sticker_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Sticker{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_sticker(changeset, sticker_data) do
    changeset
    |> maybe_set_attribute(:discord_id, sticker_data.id)
    |> maybe_set_attribute(:name, sticker_data.name)
    |> maybe_set_attribute(:pack_id, sticker_data.pack_id)
    |> maybe_set_attribute(:description, sticker_data.description)
    |> maybe_set_attribute(:tags, sticker_data.tags)
    |> maybe_set_attribute(:type, sticker_data.type)
    |> maybe_set_attribute(:format_type, sticker_data.format_type)
    |> maybe_set_attribute(:available, sticker_data.available)
    |> maybe_set_attribute(:sort_value, sticker_data.sort_value)
    |> maybe_set_attribute(:guild_discord_id, sticker_data.guild_id)
    |> maybe_set_attribute(:guild_id, sticker_data.guild_id)
    |> maybe_set_user_discord_id(sticker_data.user)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_set_user_discord_id(changeset, nil), do: changeset

  defp maybe_set_user_discord_id(changeset, %{id: user_id}) do
    maybe_set_attribute(changeset, :user_discord_id, user_id)
  end

  defp maybe_set_user_discord_id(changeset, _), do: changeset
end
