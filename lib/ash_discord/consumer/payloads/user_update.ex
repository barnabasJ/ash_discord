defmodule AshDiscord.Consumer.Payloads.UserUpdate do
  @moduledoc """
  TypedStruct for Discord USER_UPDATE event payload.

  Contains old and new user data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.User

  typed_struct do
    field :old_user, User,
      allow_nil?: true,
      description: "The previous user state (may be nil if not cached)"

    field :new_user, User,
      allow_nil?: false,
      description: "The updated user state"
  end
end
