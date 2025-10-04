defmodule AshDiscord.Consumer.Payloads.GuildRoleUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_ROLE_UPDATE event payload.

  Contains guild ID and old/new role data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_role, AshDiscord.Consumer.Payloads.Role,
      allow_nil?: true,
      description: "The previous role state (may be nil if not cached)"

    field :new_role, AshDiscord.Consumer.Payloads.Role,
      allow_nil?: false,
      description: "The updated role state"
  end

  @doc """
  Create a GuildRoleUpdate TypedStruct from Nostrum guild role update event data.

  Accepts a tuple `{guild_id, old_role, new_role}` where roles are `Nostrum.Struct.Guild.Role.t()`.
  """
  def new({guild_id, old_role, %Nostrum.Struct.Guild.Role{} = new_role})
      when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      old_role: old_role && AshDiscord.Consumer.Payloads.Role.new(old_role),
      new_role: AshDiscord.Consumer.Payloads.Role.new(new_role)
    })
  end
end
