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

  alias AshDiscord.Changes.FromDiscord.Transformations

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
    user_discord_id = user.id

    changeset
    |> maybe_manage_guild_relationship(guild_id)
    |> maybe_manage_user_relationship(user_discord_id)
  end

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
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
end
