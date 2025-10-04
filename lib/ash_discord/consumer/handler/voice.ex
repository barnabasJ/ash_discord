defmodule AshDiscord.Consumer.Handler.Voice do
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec update(
          consumer :: module(),
          voice_state_event :: Payloads.VoiceStateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(consumer, voice_state, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_voice_state_resource(consumer) do
      {:ok, resource} ->
        Logger.debug("AshDiscord: Creating voice state: #{inspect(voice_state)}")

        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 data: voice_state
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
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ready(_consumer, _data, _ws_state, _context) do
    :ok
  end

  @spec speaking(
          consumer :: module(),
          data :: Nostrum.Struct.Event.SpeakingUpdate.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def speaking(_consumer, _data, _ws_state, _context) do
    :ok
  end

  @spec incoming(
          consumer :: module(),
          data :: Nostrum.Voice.rtp_opus(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def incoming(_consumer, _data, _ws_state, _context) do
    :ok
  end

  @spec server(
          consumer :: module(),
          data :: Nostrum.Struct.Event.VoiceServerUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def server(_consumer, _data, _ws_state, _context) do
    :ok
  end
end
