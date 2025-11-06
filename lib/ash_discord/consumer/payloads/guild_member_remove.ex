defmodule AshDiscord.Consumer.Payloads.GuildMemberRemove do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_REMOVE event payload.

  Contains guild ID and member data of the removed member.

  ## References
  - [Discord API - Guild Member Remove Event](https://discord.com/developers/docs/topics/gateway-events#guild-member-remove)
  - [Nostrum - Guild.Member](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Member.html)
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
    {:ok, member_payload} = AshDiscord.Consumer.Payloads.Member.new(old_member)

    super(%{
      guild_id: guild_id,
      member: member_payload
    })
  end
end
