defmodule AshDiscord.Consumer.Payloads.GuildMemberUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_UPDATE event payload.

  Contains guild ID and old/new member data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Member

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_member, Member,
      allow_nil?: true,
      description: "The previous member state (may be nil if not cached)"

    field :new_member, Member,
      allow_nil?: false,
      description: "The updated member state"
  end
end
