defmodule AshDiscord.Consumer.Handler.Typing do
  require Logger

  @spec start(
          consumer :: module(),
          typing_data :: Nostrum.Struct.Event.TypingStart.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def start(consumer, typing_data, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_typing_indicator_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            data: typing_data
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
