defmodule AshDiscord.Consumer.Payloads.AutoModerationRule do
  @moduledoc """
  TypedStruct wrapper for Discord AutoModerationRule data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.AutoModerationRule.t()`.

  ## References
  - [Discord API - Auto Moderation Rule](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object)
  - [Nostrum - AutoModerationRule](https://hexdocs.pm/nostrum/Nostrum.Struct.AutoModerationRule.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "ID of the rule"
    field :guild_id, :integer, allow_nil?: false, description: "Guild ID this rule belongs to"
    field :name, :string, allow_nil?: false, description: "Name of the rule"

    field :creator_id, :integer,
      allow_nil?: false,
      description: "User ID which created the rule"

    field :event_type, :integer,
      allow_nil?: false,
      description: "Indicates in what event context a rule should be checked (1 = message send)"

    field :trigger_type, :integer,
      allow_nil?: false,
      description:
        "Characterizes the type of content which can trigger the rule (1 = keyword, 3 = spam, 4 = keyword preset, 5 = mention spam, 6 = member profile)"

    field :trigger_metadata, :map,
      allow_nil?: true,
      description:
        "Additional metadata used to determine whether a rule should be triggered (optional)"

    field :actions, {:array, :map},
      allow_nil?: false,
      description: "Actions which will execute when the rule is triggered"

    field :enabled, :boolean,
      allow_nil?: false,
      description: "Whether the rule is enabled"

    field :exempt_roles, {:array, :integer},
      allow_nil?: true,
      description: "Roles that should not be affected by the rule (optional, maximum of 20)"

    field :exempt_channels, {:array, :integer},
      allow_nil?: true,
      description: "Channels that should not be affected by the rule (optional, maximum of 50)"
  end

  @doc """
  Create an AutoModerationRule TypedStruct from a Nostrum AutoModerationRule struct.

  Accepts a `Nostrum.Struct.AutoModerationRule.t()` and creates an AshDiscord AutoModerationRule TypedStruct.
  Also handles being passed an AutoModerationRule payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = rule_payload) do
    {:ok, rule_payload}
  end

  def new(%Nostrum.Struct.AutoModerationRule{} = nostrum_auto_moderation_rule) do
    super(Map.from_struct(nostrum_auto_moderation_rule))
  end
end
