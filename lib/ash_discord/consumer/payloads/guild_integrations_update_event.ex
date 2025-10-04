defmodule AshDiscord.Consumer.Payloads.GuildIntegrationsUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_INTEGRATIONS_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.GuildIntegrationsUpdate.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, allow_nil?: false, description: "Guild ID"
  end

  @doc """
  Create a GuildIntegrationsUpdateEvent TypedStruct from a Nostrum GuildIntegrationsUpdate event struct.

  Accepts a `Nostrum.Struct.Event.GuildIntegrationsUpdate.t()` and creates an AshDiscord GuildIntegrationsUpdateEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.GuildIntegrationsUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
