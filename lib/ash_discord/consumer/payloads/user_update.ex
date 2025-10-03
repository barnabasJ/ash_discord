defmodule AshDiscord.Consumer.Payloads.UserUpdate do
  @moduledoc """
  TypedStruct for Discord USER_UPDATE event payload.

  Contains old and new user data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_user, AshDiscord.Consumer.Payloads.User,
      allow_nil?: true,
      description: "The previous user state (may be nil if not cached)"

    field :new_user, AshDiscord.Consumer.Payloads.User,
      allow_nil?: false,
      description: "The updated user state"
  end

  @doc """
  Create a UserUpdate TypedStruct from Nostrum user update event data.

  Accepts a tuple `{old_user, new_user}` where each is a `Nostrum.Struct.User.t()`.
  """
  def new({old_user, %Nostrum.Struct.User{} = new_user}) do
    super(%{
      old_user: old_user && AshDiscord.Consumer.Payloads.User.new(old_user),
      new_user: AshDiscord.Consumer.Payloads.User.new(new_user)
    })
  end
end
