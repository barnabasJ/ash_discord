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
end
