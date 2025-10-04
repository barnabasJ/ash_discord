defmodule AshDiscord.Consumer.Payloads.GuildRoleDelete do
  @moduledoc """
  TypedStruct for Discord GUILD_ROLE_DELETE event payload.

  Contains guild ID and deleted role data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :role, AshDiscord.Consumer.Payloads.Role,
      allow_nil?: false,
      description: "The deleted role"
  end

  @doc """
  Create a GuildRoleDelete TypedStruct from Nostrum guild role delete event data.

  Accepts a tuple `{guild_id, old_role}` where old_role is a `Nostrum.Struct.Guild.Role.t()`.
  """
  def new({guild_id, %Nostrum.Struct.Guild.Role{} = old_role}) when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      role: AshDiscord.Consumer.Payloads.Role.new(old_role)
    })
  end
end
