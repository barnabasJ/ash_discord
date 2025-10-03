defmodule AshDiscord.Consumer.Payloads.GuildRoleDelete do
  @moduledoc """
  TypedStruct for Discord GUILD_ROLE_DELETE event payload.

  Contains guild ID and deleted role data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Role

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :role, Role,
      allow_nil?: false,
      description: "The deleted role"
  end
end
