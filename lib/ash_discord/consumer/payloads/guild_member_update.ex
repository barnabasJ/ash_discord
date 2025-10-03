defmodule AshDiscord.Consumer.Payloads.GuildMemberUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_MEMBER_UPDATE event payload.

  Contains guild ID and old/new member data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_member, AshDiscord.Consumer.Payloads.Member,
      allow_nil?: true,
      description: "The previous member state (may be nil if not cached)"

    field :new_member, AshDiscord.Consumer.Payloads.Member,
      allow_nil?: false,
      description: "The updated member state"
  end

  @doc """
  Create a GuildMemberUpdate TypedStruct from Nostrum guild member update event data.

  Accepts a tuple `{guild_id, old_member, new_member}` where members are `Nostrum.Struct.Guild.Member.t()`.
  """
  def new({guild_id, old_member, %Nostrum.Struct.Guild.Member{} = new_member})
      when is_integer(guild_id) do
    super(%{
      guild_id: guild_id,
      old_member: old_member && AshDiscord.Consumer.Payloads.Member.new(old_member),
      new_member: AshDiscord.Consumer.Payloads.Member.new(new_member)
    })
  end
end
