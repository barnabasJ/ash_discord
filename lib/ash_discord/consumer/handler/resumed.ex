defmodule AshDiscord.Consumer.Handler.Resumed do
  alias AshDiscord.Consumer.Handler

  @spec resumed(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:ok, term()} | Ash.BulkResult.t() | {:error, term()}
  def resumed(_consumer, _data, _ws_state, context) do
    Handler.invoke_configured_action(
      :RESUMED,
      nil,
      %{},
      context
    )
  end
end
