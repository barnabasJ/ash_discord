defmodule AshDiscord.Consumer.Handler.AutoModerationRule do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(rule, _ws_state, context) do
    case Handler.invoke_configured_action(
           :AUTO_MODERATION_RULE_CREATE,
           rule.id,
           %{identity: %{guild_id: rule.guild_id, rule_id: rule.id}, data: rule},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec delete(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(rule, _ws_state, context) do
    case Handler.invoke_configured_action(
           :AUTO_MODERATION_RULE_DELETE,
           %{discord_id: rule.id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec update(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(rule, _ws_state, context) do
    case Handler.invoke_configured_action(
           :AUTO_MODERATION_RULE_UPDATE,
           rule.id,
           %{identity: %{guild_id: rule.guild_id, rule_id: rule.id}, data: rule},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec execute(
          data :: Payloads.AutoModerationRuleExecute.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def execute(data, _ws_state, context) do
    case Handler.invoke_configured_action(
           :AUTO_MODERATION_RULE_EXECUTE,
           nil,
           %{data: data},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
