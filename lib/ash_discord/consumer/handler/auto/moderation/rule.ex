defmodule AshDiscord.Consumer.Handler.Auto.Moderation.Rule do
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(rule, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: rule})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _rule_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(rule, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(discord_id == ^rule.id)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
    end
  end

  @spec update(
          rule :: Payloads.AutoModerationRule.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(rule, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: rule})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _rule_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec execute(
          data :: Payloads.AutoModerationRuleExecute.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def execute(data, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: data})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _execution_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
