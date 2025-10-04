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
  If already a Payloads.User struct, returns it as-is.
  """
  # TODO: This clause shouldn't be necessary - Ash's type system should handle this.
  # When we pass %Payloads.User{} to Ash.Changeset.for_create(..., %{data: user}),
  # Ash calls cast_input/2 which calls .new() again. This should be a no-op for
  # already-typed data. Investigate if Ash.TypedStruct can handle this automatically.
  def new(%__MODULE__{} = user) do
    {:ok, user}
  end

  def new(%Nostrum.Struct.User{} = nostrum_user) do
    super(Map.from_struct(nostrum_user))
  end
end
