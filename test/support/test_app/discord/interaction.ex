defmodule TestApp.Discord.Interaction do
  @moduledoc """
  Test Discord Interaction resource for validating interaction transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:interaction)
  end

  ets do
    private?(true)
  end

  relationships do
    belongs_to :guild, TestApp.Discord.Guild do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:guild_discord_id)
      allow_nil?(true)
      attribute_writable?(true)
    end

    belongs_to :channel, TestApp.Discord.Channel do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:channel_discord_id)
      attribute_writable?(true)
    end

    belongs_to :user, TestApp.Discord.User do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:user_discord_id)
      attribute_writable?(true)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:application_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:token, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:data, :map,
      allow_nil?: true,
      public?: true
    )

    attribute(:locale, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:app_permissions, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:version, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_locale, :string,
      allow_nil?: true,
      public?: true
    )
  end

  identities do
    identity :discord_id, [:discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create interaction from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Interaction,
        allow_nil?: true,
        description: "Discord interaction TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.Interaction)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :application_id,
        :type,
        :guild_discord_id,
        :channel_discord_id,
        :user_discord_id,
        :token,
        :data,
        :locale,
        :app_permissions,
        :version,
        :guild_locale
      ])
    end

    update :update do
      primary?(true)

      accept([
        :application_id,
        :type,
        :guild_discord_id,
        :channel_discord_id,
        :user_discord_id,
        :token,
        :data,
        :locale,
        :app_permissions,
        :version,
        :guild_locale
      ])
    end
  end
end
