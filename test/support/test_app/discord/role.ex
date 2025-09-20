defmodule TestApp.Discord.Role do
  @moduledoc """
  Test Discord Role resource for validating role transformations.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:color, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:permissions, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:hoist, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:position, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:managed, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:mentionable, :boolean,
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
      description("Create role from Discord data")
      primary?(true)

      argument(:discord_struct, :map,
        allow_nil?: false,
        description: "Discord role struct to transform"
      )

      change({AshDiscord.Changes.FromDiscord, type: :role})

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:name, :color, :permissions, :hoist, :position, :managed, :mentionable])
    end

    update :update do
      primary?(true)
      accept([:name, :color, :permissions, :hoist, :position, :managed, :mentionable])
    end
  end
end
