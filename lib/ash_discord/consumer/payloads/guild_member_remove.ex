defmodule AshDiscord.Consumer.Payloads.GuildMemberRemove do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_REMOVE event payload.

  Contains guild ID and user data of the removed member.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.User

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :user, User,
      allow_nil?: false,
      description: "The user that was removed from the guild"
  end
end
