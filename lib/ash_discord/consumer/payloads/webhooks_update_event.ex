defmodule AshDiscord.Consumer.Payloads.WebhooksUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord WEBHOOKS_UPDATE event data.

  Wraps map() to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The WEBHOOKS_UPDATE event data map"
  end
end
