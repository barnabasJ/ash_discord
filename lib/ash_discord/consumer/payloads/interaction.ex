defmodule AshDiscord.Consumer.Payloads.Interaction do
  @moduledoc """
  TypedStruct wrapper for Discord Interaction data.

  Wraps `Nostrum.Struct.Interaction.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Interaction struct"
  end
end
