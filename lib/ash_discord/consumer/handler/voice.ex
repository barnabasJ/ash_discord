defmodule AshDiscord.Consumer.Handler.Voice do
  require Logger

  @spec state(
          consumer :: module(),
          voice_state :: Nostrum.Struct.Event.VoiceState.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def state(consumer, voice_state, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_voice_state_resource(consumer) do
      {:ok, resource} ->
        Logger.debug("AshDiscord: Creating voice state: #{inspect(voice_state)}")

        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 discord_struct: voice_state
               },
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, voice_state_record} ->
            Logger.info("AshDiscord: Voice state created: #{inspect(voice_state_record)}")
            :ok

          {:error, error} ->
            Logger.error("AshDiscord: Failed to create voice state: #{inspect(error)}")
            :ok
        end

      :error ->
        Logger.warning("No voice state resource configured")
        :ok
    end
  end

  @spec ready(
          consumer :: module(),
          data :: Nostrum.Struct.Event.VoiceReady.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t()
        ) :: any()
  def ready(_consumer, _data, _ws_state) do
    :ok
  end

  @spec speaking(
          consumer :: module(),
          data :: Nostrum.Struct.Event.SpeakingUpdate.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t()
        ) :: any()
  def speaking(_consumer, _data, _ws_state) do
    :ok
  end

  @spec incoming(
          consumer :: module(),
          data :: Nostrum.Voice.rtp_opus(),
          ws_state :: Nostrum.Struct.VoiceWSState.t()
        ) :: any()
  def incoming(_consumer, _data, _ws_state) do
    :ok
  end

  @spec server(
          consumer :: module(),
          data :: Nostrum.Struct.Event.VoiceServerUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def server(_consumer, _data, _ws_state) do
    :ok
  end
end
