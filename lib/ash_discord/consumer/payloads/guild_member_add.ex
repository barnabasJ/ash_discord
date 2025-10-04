defmodule AshDiscord.Consumer.Payloads.GuildMemberAdd do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_ADD event payload.

  Contains guild ID and new member data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :member, AshDiscord.Consumer.Payloads.Member,
      allow_nil?: false,
      description: "The new guild member"
  end

  @doc """
  Create a GuildMemberAdd TypedStruct from Nostrum guild member add event data.

  Accepts a tuple `{guild_id, new_member}` where new_member is a `Nostrum.Struct.Guild.Member.t()`.
  """
  def new({guild_id, %Nostrum.Struct.Guild.Member{} = new_member}) when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      member: AshDiscord.Consumer.Payloads.Member.new(new_member)
    })
  end
end
