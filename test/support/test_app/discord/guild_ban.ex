defmodule TestApp.Discord.GuildBan do
  @moduledoc """
  Test Discord Guild Ban resource for validating ban event transformations.
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
      public?: true,
      description: "Discord user ID (banned user)"
    )

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Discord guild ID where ban occurred"
    )

    attribute(:user_id, :integer,
      allow_nil?: true,
      public?: true,
      description: "Discord user ID (same as discord_id)"
    )
  end

  identities do
    identity :discord_id, [:discord_id, :guild_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create guild ban from Discord event data")
      primary?(true)

      argument(:data, :map,
        allow_nil?: false,
        description: "Map with guild_id and user from ban event"
      )

      change(AshDiscord.Changes.FromDiscord.GuildBan)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :user_id
      ])
    end

    update :update do
      primary?(true)
      accept([:guild_id, :user_id])
    end
  end
end
