defmodule AshDiscord.Consumer.Handler.Typing do
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec start(
          consumer :: module(),
          typing_start :: Payloads.TypingStartEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def start(consumer, typing_start, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_typing_indicator_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            data: typing_start
          },
          context: %{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          }
        )
        |> Ash.create()

      :error ->
        Logger.warning("No typing indicator resource configured")
        {:error, "No typing indicator resource configured"}
    end

    :ok
  end
end
