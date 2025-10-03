defmodule AshDiscord.Consumer.Payloads.GuildRoleCreate do
  @moduledoc """
  TypedStruct for Discord GUILD_ROLE_CREATE event payload.

  Contains guild ID and new role data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :role, AshDiscord.Consumer.Payloads.Role,
      allow_nil?: false,
      description: "The new role"
  end

  @doc """
  Create a GuildRoleCreate TypedStruct from Nostrum guild role create event data.

  Accepts a tuple `{guild_id, new_role}` where new_role is a `Nostrum.Struct.Guild.Role.t()`.
  """
  def new({guild_id, %Nostrum.Struct.Guild.Role{} = new_role}) when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      role: AshDiscord.Consumer.Payloads.Role.new(new_role)
    })
  end
end
