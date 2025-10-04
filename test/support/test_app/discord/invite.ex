defmodule TestApp.Discord.Invite do
  @moduledoc """
  Test Discord Invite resource for validating invite transformations.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:code, :string,
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

    attribute(:inviter_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:target_user_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:target_user_type, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:approximate_presence_count, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:approximate_member_count, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:uses, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:max_uses, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:max_age, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:temporary, :boolean,
      allow_nil?: true,
      public?: true
    )

    attribute(:created_at, :utc_datetime,
      allow_nil?: true,
      public?: true
    )

    attribute(:expires_at, :utc_datetime,
      allow_nil?: true,
      public?: true
    )
  end

  relationships do
    belongs_to(:guild, TestApp.Discord.Guild,
      source_attribute: :guild_discord_id,
      destination_attribute: :discord_id,
      allow_nil?: true,
      public?: true
    )

    belongs_to(:channel, TestApp.Discord.Channel,
      source_attribute: :channel_discord_id,
      destination_attribute: :discord_id,
      allow_nil?: false,
      public?: true
    )
  end

  identities do
    identity :code, [:code] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create invite from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Invite,
        allow_nil?: true,
        description: "Discord invite TypedStruct data"
      )

      argument(:identity, :string,
        allow_nil?: true,
        description: "Discord invite code for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.Invite)

      upsert?(true)
      upsert_identity(:code)

      upsert_fields([
        :guild_discord_id,
        :channel_discord_id,
        :inviter_discord_id,
        :target_user_discord_id,
        :target_user_type,
        :approximate_presence_count,
        :approximate_member_count,
        :uses,
        :max_uses,
        :max_age,
        :temporary,
        :created_at,
        :expires_at
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_discord_id,
        :channel_discord_id,
        :inviter_discord_id,
        :target_user_discord_id,
        :target_user_type,
        :approximate_presence_count,
        :approximate_member_count,
        :uses,
        :max_uses,
        :max_age,
        :temporary,
        :created_at,
        :expires_at
      ])
    end
  end
end
