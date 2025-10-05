defmodule AshDiscord.Changes.FromDiscord.GuildBan do
  @moduledoc """
  Transforms Discord Guild Ban event data into Ash resource attributes.

  This change handles creating guild ban records from Discord ban events.
  Ban events are informational only and contain guild_id and user data.

  ## Arguments

  - `:data` - Map with `%{guild_id: integer, user: User.t()}` from ban event

  ## Example

      create :from_discord do
        argument :data, :map

        change AshDiscord.Changes.FromDiscord.GuildBan
      end
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      nil ->
        Ash.Changeset.add_error(changeset, "data argument is required")

      %{guild_id: guild_id, user: user} ->
        transform_ban(changeset, guild_id, user)

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected map with guild_id and user, got: #{inspect(other)}"
        )
    end
  end

  defp transform_ban(changeset, guild_id, user) do
    changeset
    |> maybe_set_attribute(:discord_id, user.id)
    |> maybe_set_attribute(:guild_id, guild_id)
    |> maybe_set_attribute(:user_id, user.id)
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
