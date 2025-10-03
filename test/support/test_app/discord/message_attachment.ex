defmodule TestApp.Discord.MessageAttachment do
  @moduledoc """
  Test Discord MessageAttachment resource for validating attachment transformations.
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

    attribute(:filename, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:size, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:url, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:proxy_url, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:height, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:width, :integer,
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
      description("Create message attachment from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.MessageAttachment,
        allow_nil?: true,
        description: "Discord message attachment TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.MessageAttachment)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:filename, :size, :url, :proxy_url, :height, :width])
    end

    update :update do
      primary?(true)
      accept([:filename, :size, :url, :proxy_url, :height, :width])
    end
  end
end
