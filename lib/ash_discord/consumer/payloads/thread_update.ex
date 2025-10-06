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
  """
  def new({old_thread, %Nostrum.Struct.Channel{} = new_thread}) do
    super(%{
      old_thread: old_thread && AshDiscord.Consumer.Payloads.Thread.new(old_thread),
      new_thread: AshDiscord.Consumer.Payloads.Thread.new(new_thread)
    })
  end
end
