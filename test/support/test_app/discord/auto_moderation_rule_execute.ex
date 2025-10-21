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

  relationships do
    belongs_to :guild, TestApp.Discord.Guild do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:guild_discord_id)
    end

    belongs_to :user, TestApp.Discord.User do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:user_discord_id)
    end

    has_one :rule, TestApp.Discord.AutoModerationRule do
      public?(true)
      no_attributes?(true)
      could_be_related_at_creation?(true)

      filter(
        expr(
          discord_id == parent(:rule_discord_id) and
            guild_discord_id == parent(:guild_discord_id)
        )
      )
    end

    belongs_to :channel, TestApp.Discord.Channel do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:channel_discord_id)
    end

    belongs_to :message, TestApp.Discord.Message do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:message_discord_id)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:action, :map,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:rule_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:rule_trigger_type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:message_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:alert_system_message_discord_id, :integer,
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
        :guild_discord_id,
        :action,
        :rule_discord_id,
        :rule_trigger_type,
        :user_discord_id,
        :channel_discord_id,
        :message_discord_id,
        :alert_system_message_discord_id,
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
        :guild_discord_id,
        :action,
        :rule_discord_id,
        :rule_trigger_type,
        :user_discord_id,
        :channel_discord_id,
        :message_discord_id,
        :alert_system_message_discord_id,
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
