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

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:inviter_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:target_user_id, :integer,
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

    attribute(:created_at, :string,
      allow_nil?: true,
      public?: true
    )
  end

  identities do
    identity :code, [:code] do
      pre_check_with(TestApp.Discord)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create invite from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: true,
        description: "Discord invite struct to transform"
      )

      argument(:discord_id, :string,
        allow_nil?: true,
        description: "Discord invite code for API fallback"
      )

      change({AshDiscord.Changes.FromDiscord, type: :invite})

      upsert?(true)
      upsert_identity(:code)

      upsert_fields([
        :guild_id,
        :channel_id,
        :inviter_id,
        :target_user_id,
        :target_user_type,
        :approximate_presence_count,
        :approximate_member_count,
        :uses,
        :max_uses,
        :max_age,
        :temporary,
        :created_at
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_id,
        :channel_id,
        :inviter_id,
        :target_user_id,
        :target_user_type,
        :approximate_presence_count,
        :approximate_member_count,
        :uses,
        :max_uses,
        :max_age,
        :temporary,
        :created_at
      ])
    end
  end
end
