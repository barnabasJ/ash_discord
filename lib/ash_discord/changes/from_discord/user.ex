defmodule AshDiscord.Changes.FromDiscord.User do
  @moduledoc """
  Transforms Discord User data into Ash resource attributes.

  This change handles creating/updating User resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.User.t()` with Discord user data
  - `:identity` - Integer Discord user ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.User
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.User
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case ApiFetchers.fetch_user(identity) do
            {:ok, %Payloads.User{} = user_data} ->
              transform_user(changeset, user_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.User{} = user_data ->
          # Data provided directly, use it
          transform_user(changeset, user_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.User{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_user(changeset, user_data) do
    changeset
    |> maybe_set_attribute(:discord_id, user_data.id)
    |> maybe_set_attribute(:discord_username, user_data.username)
    |> maybe_set_attribute(:discord_avatar, user_data.avatar)
    |> Transformations.set_discord_email(user_data.id)
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
