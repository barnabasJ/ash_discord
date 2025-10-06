defmodule TestApp.Discord.Thread do
  @moduledoc """
  Test Discord Thread resource for validating thread transformations.

  Threads are represented as Channel objects in Discord (types 10, 11, 12).
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:parent_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:owner_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:message_count, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:member_count, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:thread_metadata, :map,
      allow_nil?: true,
      public?: true
    )

    attribute(:rate_limit_per_user, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:last_message_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:last_pin_timestamp, :utc_datetime,
      allow_nil?: true,
      public?: true
    )

    attribute(:default_auto_archive_duration, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:newly_created, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:applied_tags, {:array, :integer},
      allow_nil?: true,
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
        :name,
        :type,
        :parent_id,
        :guild_id,
        :owner_id,
        :message_count,
        :member_count,
        :thread_metadata,
        :rate_limit_per_user,
        :last_message_id,
        :last_pin_timestamp,
        :default_auto_archive_duration,
        :newly_created,
        :applied_tags
      ])
    end

    create :from_discord do
      description("Create thread from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Thread,
        allow_nil?: true,
        description: "Discord thread TypedStruct data"
      )

      argument(:identity, :integer,
        allow_nil?: true,
        description: "Discord thread ID for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.Thread)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :name,
        :type,
        :parent_id,
        :guild_id,
        :owner_id,
        :message_count,
        :member_count,
        :thread_metadata,
        :rate_limit_per_user,
        :last_message_id,
        :last_pin_timestamp,
        :default_auto_archive_duration,
        :newly_created,
        :applied_tags
      ])
    end

    update :update do
      primary?(true)

      accept([
        :name,
        :type,
        :parent_id,
        :guild_id,
        :owner_id,
        :message_count,
        :member_count,
        :thread_metadata,
        :rate_limit_per_user,
        :last_message_id,
        :last_pin_timestamp,
        :default_auto_archive_duration,
        :newly_created,
        :applied_tags
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
