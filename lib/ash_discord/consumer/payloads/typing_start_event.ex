defmodule AshDiscord.Consumer.Payloads.TypingStartEvent do
  @moduledoc """
  TypedStruct wrapper for Discord TYPING_START event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.TypingStart.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel in which the user started typing"

    field :guild_id, :integer,
      description: "ID of the guild where the user started typing (if applicable)"

    field :user_id, :integer, allow_nil?: false, description: "ID of the user who started typing"

    field :timestamp, :utc_datetime,
      allow_nil?: false,
      description: "Unix time (in seconds) of when the user started typing"

    field :member, AshDiscord.Consumer.Payloads.Member,
      description: "Member who started typing (if in a guild)"
  end

  @doc """
  Create a TypingStartEvent TypedStruct from a Nostrum TypingStart event struct.

  Accepts a `Nostrum.Struct.Event.TypingStart.t()` and creates an AshDiscord TypingStartEvent TypedStruct.
  If already a TypingStartEvent struct, returns it as-is.
  """
  # TODO: This clause shouldn't be necessary - Ash's type system should handle this.
  # When we pass %TypingStartEvent{} to Ash.Changeset.for_create(..., %{data: event}),
  # Ash calls cast_input/2 which calls .new() again. This should be a no-op for
  # already-typed data. Investigate if Ash.TypedStruct can handle this automatically.
  def new(%__MODULE__{} = event) do
    {:ok, event}
  end

  def new(%Nostrum.Struct.Event.TypingStart{} = nostrum_event) do
    attrs = nostrum_event |> Map.from_struct() |> convert_timestamp()
    super(attrs)
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    attrs = convert_timestamp(attrs)
    super(attrs)
  end

  # Convert Unix timestamp (integer seconds) to DateTime
  defp convert_timestamp(%{timestamp: timestamp} = attrs) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp, :second) do
      {:ok, dt} -> %{attrs | timestamp: dt}
      {:error, _} -> %{attrs | timestamp: DateTime.utc_now()}
    end
  end

  defp convert_timestamp(%{timestamp: %DateTime{}} = attrs), do: attrs
  defp convert_timestamp(attrs), do: attrs
end
