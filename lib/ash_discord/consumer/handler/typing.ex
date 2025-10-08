defmodule AshDiscord.Consumer.Handler.Typing do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec start(
          typing_start :: Payloads.TypingStartEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def start(typing_start, _ws_state, context) do
    case Handler.invoke_configured_action(
           :TYPING_START,
           %{user_id: typing_start.user_id, channel_id: typing_start.channel_id},
           %{data: typing_start},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
