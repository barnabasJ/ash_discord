defmodule AshDiscord.Consumer.Handler.Typing do
  alias AshDiscord.Consumer.Payloads

  @spec start(
          typing_start :: Payloads.TypingStartEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def start(typing_start, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: typing_start})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _typing_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
