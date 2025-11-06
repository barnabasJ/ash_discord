defmodule TestApp.Discord.Webhook do
  @moduledoc """
  Test Discord Webhook resource for validating webhook transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:webhook)
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

    attribute(:avatar, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:token, :string,
      allow_nil?: true,
      public?: true,
      sensitive?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:type, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:source_guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:source_channel_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:url, :string,
      allow_nil?: true,
      public?: true
    )
  end

  relationships do
    belongs_to :user, TestApp.Discord.User do
      source_attribute(:user_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :source_guild, TestApp.Discord.Guild do
      source_attribute(:source_guild_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :source_channel, TestApp.Discord.Channel do
      source_attribute(:source_channel_discord_id)
      destination_attribute(:discord_id)
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

    create :from_discord do
      description("Create webhook from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Webhook,
        allow_nil?: true,
        description: "Discord webhook TypedStruct data"
      )

      argument(:identity, :integer,
        allow_nil?: true,
        description: "Discord webhook ID for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.Webhook)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :type,
        :guild_discord_id,
        :channel_discord_id,
        :user_discord_id,
        :source_guild_discord_id,
        :source_channel_discord_id,
        :name,
        :avatar,
        :token,
        :application_id,
        :url
      ])
    end

    update :update do
      primary?(true)

      accept([
        :type,
        :guild_discord_id,
        :channel_discord_id,
        :user_discord_id,
        :source_guild_discord_id,
        :source_channel_discord_id,
        :name,
        :avatar,
        :token,
        :application_id,
        :url
      ])
    end
  end
end
