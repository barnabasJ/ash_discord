defmodule AshDiscord.Consumer.Payloads.ThreadUpdate do
  @moduledoc """
  TypedStruct for Discord THREAD_UPDATE event payload.

  Contains old and new thread data.

  ## References
  - [Discord API - Thread Update Event](https://discord.com/developers/docs/topics/gateway-events#thread-update)
  - [Nostrum - Channel](https://hexdocs.pm/nostrum/Nostrum.Struct.Channel.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_thread, AshDiscord.Consumer.Payloads.Thread,
      allow_nil?: true,
      description: "The previous thread state (may be nil if not cached)"

    field :new_thread, AshDiscord.Consumer.Payloads.Thread,
      allow_nil?: false,
      description: "The updated thread state"
  end

  @doc """
  Create a ThreadUpdate TypedStruct from Nostrum thread update event data.

  Accepts a tuple `{old_thread, new_thread}` where each is a `Nostrum.Struct.Channel.t()`.
  Also handles being passed a ThreadUpdate payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = update_payload) do
    {:ok, update_payload}
  end

  def new({old_thread, %Nostrum.Struct.Channel{} = new_thread}) do
    {:ok, old_thread_payload} = old_thread && AshDiscord.Consumer.Payloads.Thread.new(old_thread)
    {:ok, new_thread_payload} = AshDiscord.Consumer.Payloads.Thread.new(new_thread)

    super(%{
      old_thread: old_thread_payload,
      new_thread: new_thread_payload
    })
  end
end
