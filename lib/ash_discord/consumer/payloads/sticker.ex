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
      allow_nil?: true,
      description:
        "For guild stickers, the Discord name of a unicode emoji; for standard stickers, a comma-separated list of related expressions"

    field :type, :integer,
      allow_nil?: false,
      description: "Type of sticker (1 = standard, 2 = guild - converted from Nostrum atoms)"

    field :format_type, :integer,
      allow_nil?: false,
      description:
        "Format type (1 = png, 2 = apng, 3 = lottie, 4 = gif - converted from Nostrum atoms)"

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
    # Convert Nostrum struct to map and convert atoms to integers
    nostrum_sticker
    |> Map.from_struct()
    |> Map.update(:type, nil, &map_type_to_integer/1)
    |> Map.update(:format_type, nil, &map_format_type_to_integer/1)
    |> then(&super/1)
  end

  def new(value) when is_map(value) do
    # Convert atom values to integers for Ash.TypedStruct
    value
    |> Map.update(:type, nil, &map_type_to_integer/1)
    |> Map.update(:format_type, nil, &map_format_type_to_integer/1)
    |> then(&super/1)
  end

  def new(value) do
    super(value)
  end

  # Map Nostrum's type atoms to Discord API integers
  defp map_type_to_integer(:standard), do: 1
  defp map_type_to_integer(:guild), do: 2
  defp map_type_to_integer(value) when is_integer(value), do: value
  defp map_type_to_integer(other), do: other

  # Map Nostrum's format_type atoms to Discord API integers
  defp map_format_type_to_integer(:png), do: 1
  defp map_format_type_to_integer(:apng), do: 2
  defp map_format_type_to_integer(:lottie), do: 3
  defp map_format_type_to_integer(:gif), do: 4
  defp map_format_type_to_integer(value) when is_integer(value), do: value
  defp map_format_type_to_integer(other), do: other
end
