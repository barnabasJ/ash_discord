defmodule AshDiscord.Consumer.Payloads.PresenceUpdate do
  @moduledoc """
  TypedStruct for Discord PRESENCE_UPDATE event payload.

  Contains guild ID and old/new presence data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_presence, :map,
      allow_nil?: true,
      description: "The previous presence state (may be nil if not cached)"

    field :new_presence, :map,
      allow_nil?: false,
      description: "The updated presence state"
  end

  @doc """
  Create a PresenceUpdate TypedStruct from Nostrum presence update event data.

  Accepts a tuple `{guild_id, old_presence, new_presence}` where presences are maps.
  """
  def new({guild_id, old_presence, new_presence})
      when is_integer(guild_id) and is_map(new_presence) do
    super(%{
      guild_id: guild_id,
      old_presence: old_presence,
      new_presence: new_presence
    })
  end
end
