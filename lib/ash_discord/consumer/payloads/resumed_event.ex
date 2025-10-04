defmodule AshDiscord.Consumer.Payloads.ResumedEvent do
  @moduledoc """
  TypedStruct wrapper for Discord RESUMED event data.

  Wraps map() to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The RESUMED event data map"
  end
end
