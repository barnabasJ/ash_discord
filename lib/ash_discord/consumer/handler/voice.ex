defmodule AshDiscord.Consumer.Handler.Voice do
  alias AshDiscord.Consumer.Payloads

  @spec update(
          voice_state_event :: Payloads.VoiceStateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(voice_state, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: voice_state})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _voice_state_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec ready(
          voice_ready_event :: Payloads.VoiceReadyEvent.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ready(voice_ready, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: voice_ready})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _voice_ready_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec speaking(
          voice_speaking_update :: Payloads.VoiceSpeakingUpdateEvent.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def speaking(voice_speaking_update, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: voice_speaking_update})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _voice_speaking_update_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec incoming(
          data :: Nostrum.Voice.rtp_opus(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def incoming(_data, _ws_state, _context) do
    :ok
  end

  @spec server(
          voice_server_update :: Payloads.VoiceServerUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def server(voice_server_update, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: voice_server_update})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _voice_server_update_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
