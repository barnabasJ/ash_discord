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

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:creator_id, :integer,
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
        :discord_id,
        :guild_id,
        :name,
        :creator_id,
        :event_type,
        :trigger_type,
        :trigger_metadata,
        :actions,
        :enabled,
        :exempt_roles,
        :exempt_channels
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
        :guild_id,
        :name,
        :creator_id,
        :event_type,
        :trigger_type,
        :trigger_metadata,
        :actions,
        :enabled,
        :exempt_roles,
        :exempt_channels
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_id,
        :name,
        :creator_id,
        :event_type,
        :trigger_type,
        :trigger_metadata,
        :actions,
        :enabled,
        :exempt_roles,
        :exempt_channels
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
