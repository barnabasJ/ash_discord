defmodule AshDiscord.Consumer.Payloads.Interaction do
  @moduledoc """
  TypedStruct wrapper for Discord Interaction data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Interaction.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "Interaction identifier"

    field :application_id, :integer,
      description: "ID of the application that this interaction is for"

    field :type, :integer, allow_nil?: false, description: "Interaction kind (1-5)"
    field :data, :map, description: "Interaction data payload"
    field :guild_id, :integer, description: "Guild that the interaction was sent from"
    field :channel_id, :integer, description: "Channel that the interaction was sent from"
    field :channel, :map, description: "Channel that the interaction was sent from"
    field :member, :map, description: "Guild member data for the invoking user"
    field :user, :map, description: "User object for the invoking user (if invoked in a DM)"
    field :token, :string, description: "Continuation token for responding to the interaction"
    field :version, :integer, description: "Read-only property, always 1"
    field :message, :map, description: "For components, the message they were attached to"
    field :locale, :string, description: "Selected language of the invoking user"
    field :guild_locale, :string, description: "Guild's preferred locale (if invoked in a guild)"
  end

  @doc """
  Create an Interaction TypedStruct from a Nostrum Interaction struct.

  Accepts a `Nostrum.Struct.Interaction.t()` and creates an AshDiscord Interaction TypedStruct.
  """
  def new(%Nostrum.Struct.Interaction{} = nostrum_interaction) do
    super(Map.from_struct(nostrum_interaction))
  end
end
