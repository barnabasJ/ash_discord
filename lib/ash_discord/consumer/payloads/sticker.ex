defmodule AshDiscord.Consumer.Payloads.Sticker do
  @moduledoc """
  TypedStruct wrapper for Discord Sticker data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Sticker.t()`.

  ## References
  - [Discord API - Sticker](https://discord.com/developers/docs/resources/sticker#sticker-object)
  - [Nostrum - Sticker](https://hexdocs.pm/nostrum/Nostrum.Struct.Sticker.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "ID of the sticker"

    field :pack_id, :integer,
      allow_nil?: true,
      description: "For standard stickers, ID of the pack the sticker is from"

    field :name, :string,
      allow_nil?: true,
      description: "Name of the sticker"

    field :description, :string,
      allow_nil?: true,
      description: "Description of the sticker"

    field :tags, :string,
      allow_nil?: false,
      description:
        "For guild stickers, the Discord name of a unicode emoji; for standard stickers, a comma-separated list of related expressions"

    field :type, :atom,
      allow_nil?: false,
      description: "Type of sticker (:standard or :guild)"

    field :format_type, :atom,
      allow_nil?: false,
      description: "Format type (:png, :apng, :lottie, or :gif)"

    field :available, :boolean,
      allow_nil?: true,
      description:
        "Whether this guild sticker can be used, may be false due to loss of Server Boosts"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "ID of the guild that owns this sticker"

    field :user, :map,
      allow_nil?: true,
      description: "The user that uploaded the guild sticker"

    field :sort_value, :integer,
      allow_nil?: true,
      description: "The standard sticker's sort order within its pack"
  end

  @doc """
  Create a Sticker TypedStruct from a Nostrum Sticker struct.

  Accepts a `Nostrum.Struct.Sticker.t()` and creates an AshDiscord Sticker TypedStruct.
  Also handles being passed a Sticker payload (no-op for already-converted payloads) or a raw map for validation.
  """
  def new(%__MODULE__{} = sticker_payload) do
    {:ok, sticker_payload}
  end

  def new(%Nostrum.Struct.Sticker{} = nostrum_sticker) do
    super(Map.from_struct(nostrum_sticker))
  end

  def new(value) do
    super(value)
  end
end
