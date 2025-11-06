defmodule AshDiscord.Consumer.Payloads.AutoModerationRuleExecute do
  @moduledoc """
  TypedStruct wrapper for Discord AUTO_MODERATION_RULE_EXECUTE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.AutoModerationRuleExecute.t()`.

  ## References
  - [Discord API - Auto Moderation Action Execution Event](https://discord.com/developers/docs/topics/gateway-events#auto-moderation-action-execution)
  - [Nostrum - Event.AutoModerationRuleExecute](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.AutoModerationRuleExecute.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The id of the guild in which the action was executed"

    field :action, :map, allow_nil?: false, description: "The action that was executed"

    field :rule_id, :integer,
      allow_nil?: false,
      description: "The id of the rule that was executed"

    field :rule_trigger_type, :integer,
      allow_nil?: false,
      description: "The trigger type of rule that was executed"

    field :user_id, :integer,
      allow_nil?: false,
      description: "The id of the user who triggered the rule"

    field :channel_id, :integer,
      description: "The id of the channel in which user content was posted"

    field :message_id, :integer, description: "The id of any message that triggered the rule"

    field :alert_system_message_id, :integer,
      description: "The id of the system auto moderation message posted"

    field :content, :string, allow_nil?: false, description: "The user generated text content"

    field :matched_keyword, :string,
      description: "The word or phrase configured in the rule that was matched in content"

    field :matched_content, :string,
      description: "The substring in content that triggered the rule"
  end

  @doc """
  Create an AutoModerationRuleExecute TypedStruct from a Nostrum AutoModerationRuleExecute event struct.

  Accepts a `Nostrum.Struct.Event.AutoModerationRuleExecute.t()` and creates an AshDiscord AutoModerationRuleExecute TypedStruct.
  Also handles being passed an AutoModerationRuleExecute payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = execute_payload) do
    {:ok, execute_payload}
  end

  def new(%Nostrum.Struct.Event.AutoModerationRuleExecute{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
