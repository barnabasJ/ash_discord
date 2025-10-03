defmodule AshDiscord.Consumer.Handler.Auto.Moderation.Rule do
  @spec create(
          consumer :: module(),
          rule :: Nostrum.Struct.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def create(_consumer, _rule, _ws_state), do: :ok

  @spec delete(
          consumer :: module(),
          rule :: Nostrum.Struct.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def delete(_consumer, _rule, _ws_state), do: :ok

  @spec update(
          consumer :: module(),
          rule :: Nostrum.Struct.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _rule, _ws_state), do: :ok

  @spec execute(
          consumer :: module(),
          data :: Nostrum.Struct.Event.AutoModerationRuleExecute.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def execute(_consumer, _data, _ws_state), do: :ok
end
