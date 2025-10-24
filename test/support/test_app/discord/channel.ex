defmodule TestApp.Discord.Channel do
  @moduledoc """
  Test Discord Channel resource for validating channel transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:channel)
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

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:position, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:topic, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:nsfw, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:permission_overwrites, {:array, :map},
      allow_nil?: true,
      public?: true,
      default: []
    )

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:bitrate, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:user_limit, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:rate_limit_per_user, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:recipients, {:array, :map},
      allow_nil?: true,
      public?: true
    )

    attribute(:icon, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:owner_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:last_pin_timestamp, :utc_datetime,
      allow_nil?: true,
      public?: true
    )

    attribute(:rtc_region, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:video_quality_mode, :integer,
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

    attribute(:member, :map,
      allow_nil?: true,
      public?: true
    )

    attribute(:default_auto_archive_duration, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:permissions, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:newly_created, :boolean,
      allow_nil?: true,
      public?: true
    )

    attribute(:available_tags, {:array, :map},
      allow_nil?: true,
      public?: true
    )

    attribute(:applied_tags, {:array, :integer},
      allow_nil?: true,
      public?: true
    )

    attribute(:default_reaction_emoji, :map,
      allow_nil?: true,
      public?: true
    )

    attribute(:default_thread_rate_limit_per_user, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:default_sort_order, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:default_forum_layout, :integer,
      allow_nil?: true,
      public?: true
    )
  end

  relationships do
    belongs_to :parent, TestApp.Discord.Channel do
      attribute_writable?(true)
    end

    belongs_to :last_message, TestApp.Discord.Message do
      attribute_writable?(true)
    end
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
        :position,
        :topic,
        :nsfw,
        :permission_overwrites,
        :guild_id,
        :bitrate,
        :user_limit,
        :rate_limit_per_user,
        :recipients,
        :icon,
        :owner_discord_id,
        :application_discord_id,
        :last_pin_timestamp,
        :rtc_region,
        :video_quality_mode,
        :message_count,
        :member_count,
        :thread_metadata,
        :member,
        :default_auto_archive_duration,
        :permissions,
        :newly_created,
        :available_tags,
        :applied_tags,
        :default_reaction_emoji,
        :default_thread_rate_limit_per_user,
        :default_sort_order,
        :default_forum_layout,
        :parent_discord_id,
        :last_message_discord_id
      ])
    end

    create :from_discord do
      description("Create channel from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Channel,
        allow_nil?: true,
        description: "Discord channel TypedStruct data"
      )

      argument(:identity, :integer,
        allow_nil?: true,
        description: "Discord channel ID for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.Channel)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :name,
        :type,
        :position,
        :topic,
        :nsfw,
        :permission_overwrites,
        :guild_id,
        :bitrate,
        :user_limit,
        :rate_limit_per_user,
        :recipients,
        :icon,
        :owner_discord_id,
        :application_discord_id,
        :last_pin_timestamp,
        :rtc_region,
        :video_quality_mode,
        :message_count,
        :member_count,
        :thread_metadata,
        :member,
        :default_auto_archive_duration,
        :permissions,
        :newly_created,
        :available_tags,
        :applied_tags,
        :default_reaction_emoji,
        :default_thread_rate_limit_per_user,
        :default_sort_order,
        :default_forum_layout,
        :parent_discord_id,
        :last_message_discord_id
      ])
    end

    update :update do
      primary?(true)

      accept([
        :name,
        :type,
        :position,
        :topic,
        :nsfw,
        :permission_overwrites,
        :guild_id,
        :bitrate,
        :user_limit,
        :rate_limit_per_user,
        :recipients,
        :icon,
        :owner_discord_id,
        :application_discord_id,
        :last_pin_timestamp,
        :rtc_region,
        :video_quality_mode,
        :message_count,
        :member_count,
        :thread_metadata,
        :member,
        :default_auto_archive_duration,
        :permissions,
        :newly_created,
        :available_tags,
        :applied_tags,
        :default_reaction_emoji,
        :default_thread_rate_limit_per_user,
        :default_sort_order,
        :default_forum_layout,
        :parent_discord_id,
        :last_message_discord_id
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
