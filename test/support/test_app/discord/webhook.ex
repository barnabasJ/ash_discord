defmodule TestApp.Discord.Webhook do
  @moduledoc """
  Test Discord Webhook resource for validating webhook transformations.
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

    attribute(:avatar, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:token, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_id, :integer,
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
      description("Create webhook from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: true,
        description: "Discord webhook struct to transform"
      )

      argument(:discord_id, :integer,
        allow_nil?: true,
        description: "Discord webhook ID for API fallback"
      )

      change({AshDiscord.Changes.FromDiscord, type: :webhook})

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:name, :avatar, :channel_id, :guild_id, :token])
    end

    update :update do
      primary?(true)
      accept([:name, :avatar, :channel_id, :guild_id, :token])
    end
  end
end
