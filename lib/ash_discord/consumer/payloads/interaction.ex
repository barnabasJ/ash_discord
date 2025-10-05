defmodule AshDiscord.Consumer.Payloads.Interaction do
  @moduledoc """
  TypedStruct wrapper for Discord Interaction data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Interaction.t()`.

  ## References
  - [Discord API - Interaction](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object)
  - [Nostrum - Interaction](https://hexdocs.pm/nostrum/Nostrum.Struct.Interaction.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "Interaction identifier"

    field :application_id, :integer,
      allow_nil?: false,
      description: "ID of the application that this interaction is for"

    field :type, :integer, allow_nil?: false, description: "Interaction kind (1-5)"

    field :data, :map,
      allow_nil?: true,
      description:
        "Interaction data payload (optional - present on application command, message component, and modal submit interaction types)"

    field :guild_id, :integer, description: "Guild that the interaction was sent from"
    field :channel_id, :integer, description: "Channel that the interaction was sent from"

    field :channel, :map,
      allow_nil?: true,
      description: "Partial channel object that the interaction was sent from (optional)"

    field :member, :map,
      allow_nil?: true,
      description:
        "Guild member data for the invoking user, including permissions (optional - only present in guild contexts)"

    field :user, :map, description: "User object for the invoking user (if invoked in a DM)"

    field :token, :string,
      allow_nil?: false,
      description: "Continuation token for responding to the interaction (valid for 15 minutes)"

    field :version, :integer,
      allow_nil?: false,
      description: "Read-only property, always 1"

    field :message, :map, description: "For components, the message they were attached to"

    field :locale, :string,
      allow_nil?: false,
      description:
        "Selected language of the invoking user (always present except for Ping interactions)"

    field :guild_locale, :string,
      allow_nil?: true,
      description: "Guild's preferred locale (optional - only present when invoked in a guild)"
  end

  @doc """
  Create an Interaction TypedStruct from a Nostrum Interaction struct.

  Accepts a `Nostrum.Struct.Interaction.t()` and creates an AshDiscord Interaction TypedStruct.
  Also handles being passed an Interaction payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = interaction_payload) do
    {:ok, interaction_payload}
  end

  def new(%Nostrum.Struct.Interaction{} = nostrum_interaction) do
    super(Map.from_struct(nostrum_interaction))
  end

  def new(value) do
    super(value)
  end
end
