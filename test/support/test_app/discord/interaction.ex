defmodule TestApp.Discord.Interaction do
  @moduledoc """
  Test Discord Interaction resource for validating interaction transformations.
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

    attribute(:type, :integer,
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

    attribute(:user_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:token, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:data, :map,
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
      description("Create interaction from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: false,
        description: "Discord interaction struct to transform"
      )

      change({AshDiscord.Changes.FromDiscord, type: :interaction})

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:type, :guild_id, :channel_id, :user_id, :token, :data])
    end

    update :update do
      primary?(true)
      accept([:type, :guild_id, :channel_id, :user_id, :token, :data])
    end
  end
end
