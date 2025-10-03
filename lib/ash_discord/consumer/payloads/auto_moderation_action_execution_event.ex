defmodule AshDiscord.Consumer.Payloads.AutoModerationActionExecutionEvent do
  @moduledoc """
  TypedStruct wrapper for Discord AUTO_MODERATION_ACTION_EXECUTION event data.

  Wraps `Nostrum.Struct.Event.AutoModerationRuleExecute.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.AutoModerationRuleExecute struct"
  end
end
