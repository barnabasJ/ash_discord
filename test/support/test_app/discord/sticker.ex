defmodule TestApp.Discord.Sticker do
  @moduledoc """
  Test Discord Sticker resource for validating sticker transformations.
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

    attribute(:description, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:tags, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:format_type, :integer,
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
      description("Create sticker from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: true,
        description: "Discord sticker struct to transform"
      )

      argument(:discord_id, :integer,
        allow_nil?: true,
        description: "Discord sticker ID for API fallback"
      )

      change({AshDiscord.Changes.FromDiscord, type: :sticker})

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:name, :description, :tags, :format_type, :guild_id])
    end

    update :update do
      primary?(true)
      accept([:name, :description, :tags, :format_type, :guild_id])
    end
  end
end
