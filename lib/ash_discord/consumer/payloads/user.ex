defmodule AshDiscord.Consumer.Payloads.User do
  @moduledoc """
  TypedStruct wrapper for Discord User data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.User.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The user's id"
    field :username, :string, allow_nil?: false, description: "The user's username"

    field :discriminator, :string,
      allow_nil?: false,
      description: "The user's 4-digit discord-tag"

    field :global_name, :string, description: "The user's display name, if it is set"
    field :avatar, :string, description: "User's avatar hash"
    field :bot, :boolean, description: "Whether the user is a bot"
    field :public_flags, :integer, description: "The user's public flags"
  end

  @doc """
  Create a User TypedStruct from a Nostrum User struct.

  Accepts a `Nostrum.Struct.User.t()` and creates an AshDiscord User TypedStruct.
  """
  def new(%Nostrum.Struct.User{} = nostrum_user) do
    super(Map.from_struct(nostrum_user))
  end
end
