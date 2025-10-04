defmodule AshDiscord.Consumer.Payloads.Role do
  @moduledoc """
  TypedStruct wrapper for Discord Role data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.Role.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The id of the role"
    field :name, :string, allow_nil?: false, description: "The name of the role"
    field :color, :integer, allow_nil?: false, description: "The hexadecimal color code"

    field :hoist, :boolean,
      allow_nil?: false,
      description: "Whether the role is pinned in the user listing"

    field :position, :integer, allow_nil?: false, description: "The position of the role"
    field :permissions, :integer, allow_nil?: false, description: "The permission bit set"

    field :managed, :boolean,
      allow_nil?: false,
      description: "Whether the role is managed by an integration"

    field :mentionable, :boolean,
      allow_nil?: false,
      description: "Whether the role is mentionable"

    field :icon, :string, description: "The hash of the role icon"

    field :unicode_emoji, :string,
      description: "The standard unicode character emoji icon for the role"
  end

  @doc """
  Create a Role TypedStruct from a Nostrum Guild.Role struct.

  Accepts a `Nostrum.Struct.Guild.Role.t()` and creates an AshDiscord Role TypedStruct.
  Also handles being passed a Role payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = role_payload) do
    {:ok, role_payload}
  end

  def new(%Nostrum.Struct.Guild.Role{} = nostrum_role) do
    super(Map.from_struct(nostrum_role))
  end
end
