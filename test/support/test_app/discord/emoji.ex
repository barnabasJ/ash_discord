defmodule TestApp.Discord.Emoji do
  @moduledoc """
  Test Discord Emoji resource for validating emoji transformations.
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

    attribute(:animated, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:custom, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:managed, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:require_colons, :boolean,
      allow_nil?: true,
      public?: true,
      default: true
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
      description("Create emoji from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Emoji,
        allow_nil?: true,
        description: "Discord emoji TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.Emoji)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:name, :animated, :custom, :managed, :require_colons])
    end

    update :update do
      primary?(true)
      accept([:name, :animated, :custom, :managed, :require_colons])
    end
  end
end
