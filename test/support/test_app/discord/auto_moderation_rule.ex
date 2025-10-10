defmodule TestApp.Discord.AutoModerationRule do
  @moduledoc """
  Test Discord AutoModerationRule resource for validating auto moderation rule transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:auto_moderation_rule)
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

    belongs_to :creator, TestApp.Discord.User do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:creator_discord_id)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:creator_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:event_type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:trigger_type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:trigger_metadata, :map,
      allow_nil?: true,
      public?: true
    )

    attribute(:actions, {:array, :map},
      allow_nil?: false,
      public?: true,
      default: []
    )

    attribute(:enabled, :boolean,
      allow_nil?: false,
      public?: true,
      default: false
    )

    attribute(:exempt_roles, {:array, :integer},
      allow_nil?: false,
      public?: true,
      default: []
    )

    attribute(:exempt_channels, {:array, :integer},
      allow_nil?: false,
      public?: true,
      default: []
    )
  end

  identities do
    identity :discord_id, [:discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :actions,
        :creator_discord_id,
        :discord_id,
        :enabled,
        :event_type,
        :exempt_channels,
        :exempt_roles,
        :guild_discord_id,
        :name,
        :trigger_metadata,
        :trigger_type
      ])
    end

    create :from_discord do
      description("Create auto moderation rule from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.AutoModerationRule,
        allow_nil?: true,
        description: "Discord auto moderation rule TypedStruct data"
      )

      argument(:identity, :map,
        allow_nil?: true,
        description: "Map with guild_id and rule_id for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.AutoModerationRule)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :actions,
        :creator_discord_id,
        :enabled,
        :event_type,
        :exempt_channels,
        :exempt_roles,
        :guild_discord_id,
        :name,
        :trigger_metadata,
        :trigger_type
      ])
    end

    update :update do
      primary?(true)

      accept([
        :actions,
        :creator_discord_id,
        :enabled,
        :event_type,
        :exempt_channels,
        :exempt_roles,
        :guild_discord_id,
        :name,
        :trigger_metadata,
        :trigger_type
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
