defmodule AshDiscord.Consumer.Payloads.GuildRoleUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_ROLE_UPDATE event payload.

  Contains guild ID and old/new role data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Role

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_role, Role,
      allow_nil?: true,
      description: "The previous role state (may be nil if not cached)"

    field :new_role, Role,
      allow_nil?: false,
      description: "The updated role state"
  end
end
