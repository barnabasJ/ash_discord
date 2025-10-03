defmodule AshDiscord.Consumer.Handler.Integration do
  @spec create(
          consumer :: module(),
          integration :: Nostrum.Struct.Guild.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def create(_consumer, _integration, _ws_state, _context), do: :ok

  @spec update(
          consumer :: module(),
          integration :: Nostrum.Struct.Guild.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(_consumer, _integration, _ws_state, _context), do: :ok

  @spec delete(
          consumer :: module(),
          data :: Nostrum.Struct.Event.GuildIntegrationDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def delete(_consumer, _data, _ws_state, _context), do: :ok
end
