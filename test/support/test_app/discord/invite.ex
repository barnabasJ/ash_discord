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

    attribute(:uses, :integer,
      allow_nil?: true,
      public?: true,
      default: 0
    )

    attribute(:max_uses, :integer,
      allow_nil?: true,
      public?: true,
      default: 0
    )

    attribute(:expires_at, :utc_datetime,
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
        allow_nil?: false,
        description: "Discord invite struct to transform"
      )

      change({AshDiscord.Changes.FromDiscord, type: :invite})

      upsert?(true)
      upsert_identity(:code)
      upsert_fields([:guild_id, :channel_id, :inviter_id, :uses, :max_uses, :expires_at])
    end

    update :update do
      primary?(true)
      accept([:guild_id, :channel_id, :inviter_id, :uses, :max_uses, :expires_at])
    end
  end
end
