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
          data :: Nostrum.Struct.Event.VoiceReady.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ready(_data, _ws_state, _context) do
    :ok
  end

  @spec speaking(
          data :: Nostrum.Struct.Event.SpeakingUpdate.t(),
          ws_state :: Nostrum.Struct.VoiceWSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def speaking(_data, _ws_state, _context) do
    :ok
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
          data :: Nostrum.Struct.Event.VoiceServerUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def server(_data, _ws_state, _context) do
    :ok
  end
end
