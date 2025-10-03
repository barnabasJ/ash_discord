defmodule AshDiscord.Consumer.Payloads.GuildMemberAdd do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_ADD event payload.

  Contains guild ID and new member data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Member

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :member, Member,
      allow_nil?: false,
      description: "The new guild member"
  end
end
