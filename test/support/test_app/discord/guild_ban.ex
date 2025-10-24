defmodule TestApp.Discord.GuildBan do
  @moduledoc """
  Test Discord Guild Ban resource for validating ban event transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:guild_ban)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Discord guild ID where ban occurred"
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Discord user ID of the banned user"
    )
  end

  relationships do
    belongs_to :guild, TestApp.Discord.Guild do
      source_attribute(:guild_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :user, TestApp.Discord.User do
      source_attribute(:user_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end
  end

  identities do
    identity :discord_id, [:user_discord_id, :guild_discord_id] do
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
        :user_discord_id,
        :guild_discord_id
      ])
    end

    update :update do
      primary?(true)
      accept([:guild_discord_id, :user_discord_id])
    end
  end
end
