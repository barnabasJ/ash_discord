defmodule AshDiscord.Consumer.Payloads.AutoModerationRule do
  @moduledoc """
  TypedStruct wrapper for Discord AutoModerationRule data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.AutoModerationRule.t()`.
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
      description: "Additional metadata used to determine whether a rule should be triggered"

    field :actions, {:array, :map},
      allow_nil?: false,
      description: "Actions which will execute when the rule is triggered"

    field :enabled, :boolean,
      allow_nil?: false,
      description: "Whether the rule is enabled"

    field :exempt_roles, {:array, :integer},
      allow_nil?: false,
      description: "Roles that should not be affected by the rule"

    field :exempt_channels, {:array, :integer},
      allow_nil?: false,
      description: "Channels that should not be affected by the rule"
  end

  @doc """
  Create an AutoModerationRule TypedStruct from a Nostrum AutoModerationRule struct.

  Accepts a `Nostrum.Struct.AutoModerationRule.t()` and creates an AshDiscord AutoModerationRule TypedStruct.
  """
  def new(%Nostrum.Struct.AutoModerationRule{} = nostrum_auto_moderation_rule) do
    super(Map.from_struct(nostrum_auto_moderation_rule))
  end
end
