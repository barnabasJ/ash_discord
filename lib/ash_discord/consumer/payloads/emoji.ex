defmodule AshDiscord.Consumer.Payloads.Emoji do
  @moduledoc """
  TypedStruct wrapper for Discord Emoji data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Emoji.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, description: "Id of the emoji"
    field :name, :string, allow_nil?: false, description: "Name of the emoji"
    field :roles, {:array, :integer}, description: "Roles this emoji is whitelisted to"
    field :user, :map, description: "User that created this emoji"
    field :require_colons, :boolean, description: "Whether this emoji must be wrapped in colons"
    field :managed, :boolean, description: "Whether this emoji is managed"
    field :animated, :boolean, description: "Whether this emoji is animated"
  end

  @doc """
  Create an Emoji TypedStruct from a Nostrum Emoji struct.

  Accepts a `Nostrum.Struct.Emoji.t()` and creates an AshDiscord Emoji TypedStruct.
  """
  def new(%Nostrum.Struct.Emoji{} = nostrum_emoji) do
    super(Map.from_struct(nostrum_emoji))
  end
end
