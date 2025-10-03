defmodule AshDiscord.Consumer.Payloads.GuildMemberRemove do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_REMOVE event payload.

  Contains guild ID and member data of the removed member.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :member, AshDiscord.Consumer.Payloads.Member,
      allow_nil?: false,
      description: "The member that was removed from the guild"
  end

  @doc """
  Create a GuildMemberRemove TypedStruct from Nostrum guild member remove event data.

  Accepts a tuple `{guild_id, old_member}` where old_member is a `Nostrum.Struct.Guild.Member.t()`.
  """
  def new({guild_id, %Nostrum.Struct.Guild.Member{} = old_member}) when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      member: AshDiscord.Consumer.Payloads.Member.new(old_member)
    })
  end
end
