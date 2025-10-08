defmodule AshDiscord.Consumer.Handler.Resumed do
  alias AshDiscord.Consumer.Handler

  @spec resumed(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def resumed(_consumer, data, _ws_state, context) do
    case Handler.invoke_configured_action(
           :RESUMED,
           %{},
           %{data: data},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
