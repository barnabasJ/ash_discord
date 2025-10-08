defmodule AshDiscord.Consumer.Handler.Voice do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          voice_state_event :: Payloads.VoiceStateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(voice_state, _ws_state, context) do
    case Handler.invoke_configured_action(
           :VOICE_STATE_UPDATE,
           %{user_discord_id: voice_state.user_id, guild_discord_id: voice_state.guild_id},
           %{data: voice_state},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec ready(
          voice_ready_event :: Payloads.VoiceReadyEvent.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ready(voice_ready, _ws_state, context) do
    case Handler.invoke_configured_action(
           :VOICE_READY,
           %{channel_discord_id: voice_ready.channel_id, guild_discord_id: voice_ready.guild_id},
           %{data: voice_ready},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec speaking(
          voice_speaking_update :: Payloads.VoiceSpeakingUpdateEvent.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def speaking(voice_speaking_update, _ws_state, context) do
    case Handler.invoke_configured_action(
           :VOICE_SPEAKING_UPDATE,
           %{
             channel_discord_id: voice_speaking_update.channel_id,
             guild_discord_id: voice_speaking_update.guild_id
           },
           %{data: voice_speaking_update},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec incoming(
          data :: Nostrum.Voice.rtp_opus(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def incoming(data, _ws_state, context) do
    case Handler.invoke_configured_action(
           :VOICE_INCOMING_PACKET,
           %{},
           %{data: data},
           context
         ) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec server(
          voice_server_update :: Payloads.VoiceServerUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def server(voice_server_update, _ws_state, context) do
    case Handler.invoke_configured_action(
           :VOICE_SERVER_UPDATE,
           %{guild_discord_id: voice_server_update.guild_id},
           %{data: voice_server_update},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
