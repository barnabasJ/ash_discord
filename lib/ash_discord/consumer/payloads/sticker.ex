defmodule AshDiscord.Consumer.Payloads.Sticker do
  @moduledoc """
  TypedStruct wrapper for Discord Sticker data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Sticker.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "ID of the sticker"
    field :pack_id, :integer, description: "ID of the pack the sticker is from"
    field :name, :string, description: "Name of the sticker"
    field :description, :string, description: "Description of the sticker"

    field :tags, :string,
      description: "Autocomplete/suggestion tags for the sticker (comma-separated)"

    field :type, :integer, description: "Type of sticker (1 = standard, 2 = guild)"

    field :format_type, :integer,
      description: "Format type (1 = png, 2 = apng, 3 = lottie, 4 = gif)"

    field :available, :boolean, description: "Whether this guild sticker can be used"
    field :guild_id, :integer, description: "ID of the guild that owns this sticker"
    field :user, :map, description: "User that uploaded the guild sticker"
    field :sort_value, :integer, description: "Standard sticker's sort order within its pack"
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
