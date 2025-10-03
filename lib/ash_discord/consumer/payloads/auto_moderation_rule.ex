defmodule AshDiscord.Consumer.Payloads.AutoModerationRule do
  @moduledoc """
  TypedStruct wrapper for Discord AutoModerationRule data.

  Wraps `Nostrum.Struct.AutoModerationRule.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.AutoModerationRule struct"
  end
end
