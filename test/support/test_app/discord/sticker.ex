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

    attribute(:type, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:format_type, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:available, :boolean,
      allow_nil?: true,
      public?: true,
      default: true
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

      argument(:data, AshDiscord.Consumer.Payloads.Sticker,
        allow_nil?: true,
        description: "Discord sticker TypedStruct data"
      )

      argument(:identity, :integer,
        allow_nil?: true,
        description: "Discord sticker ID for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.Sticker)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:name, :description, :tags, :type, :format_type, :available, :guild_id])
    end

    update :update do
      primary?(true)
      accept([:name, :description, :tags, :type, :format_type, :available, :guild_id])
    end
  end
end
