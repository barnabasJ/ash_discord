defmodule TestApp.Discord.AutoModerationRuleExecute do
  @moduledoc """
  Test Discord AutoModerationRuleExecute resource for validating auto moderation rule execution events.

  This is an informational event that traces when an auto moderation rule was triggered.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:auto_moderation_rule_execute)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:action, :map,
      allow_nil?: false,
      public?: true
    )

    attribute(:rule_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:rule_trigger_type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:user_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:message_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:alert_system_message_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:content, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:matched_keyword, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:matched_content, :string,
      allow_nil?: true,
      public?: true
    )
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :guild_id,
        :action,
        :rule_id,
        :rule_trigger_type,
        :user_id,
        :channel_id,
        :message_id,
        :alert_system_message_id,
        :content,
        :matched_keyword,
        :matched_content
      ])
    end

    create :from_discord do
      description("Create auto moderation rule execution event from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.AutoModerationRuleExecute,
        allow_nil?: false,
        description: "Discord auto moderation rule execution TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.AutoModerationRuleExecute)
    end

    update :update do
      primary?(true)

      accept([
        :guild_id,
        :action,
        :rule_id,
        :rule_trigger_type,
        :user_id,
        :channel_id,
        :message_id,
        :alert_system_message_id,
        :content,
        :matched_keyword,
        :matched_content
      ])
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:read)
  end
end
