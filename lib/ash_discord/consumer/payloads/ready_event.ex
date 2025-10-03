defmodule AshDiscord.Consumer.Payloads.ReadyEvent do
  @moduledoc """
  TypedStruct wrapper for Discord READY event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.Ready.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :v, :integer, allow_nil?: false, description: "Gateway version"

    field :user, AshDiscord.Consumer.Payloads.User,
      allow_nil?: false,
      description: "Information about the user including email"

    field :guilds, {:array, :map},
      allow_nil?: false,
      description: "Guilds the user is in (unavailable guild objects)"

    field :session_id, :string, allow_nil?: false, description: "Used for resuming connections"

    field :resume_gateway_url, :string,
      allow_nil?: false,
      description: "Gateway URL for resuming connections"

    field :shard, :map, description: "Shard information ([shard_id, num_shards])"

    field :application, :map,
      allow_nil?: false,
      description: "Partial application object containing app id and flags"
  end

  @doc """
  Create a ReadyEvent TypedStruct from a Nostrum Ready event struct.

  Accepts a `Nostrum.Struct.Event.Ready.t()` and creates an AshDiscord ReadyEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.Ready{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
