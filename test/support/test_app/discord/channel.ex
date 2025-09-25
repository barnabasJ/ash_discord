defmodule TestApp.Discord.Channel do
  @moduledoc """
  Test Discord Channel resource for validating channel transformations.
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

    attribute(:type, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:position, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:topic, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:nsfw, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:parent_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:permission_overwrites, {:array, :map},
      allow_nil?: true,
      public?: true,
      default: []
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

    create :create do
      accept([
        :discord_id,
        :name,
        :type,
        :position,
        :topic,
        :nsfw,
        :parent_id,
        :permission_overwrites,
        :guild_id
      ])
    end

    create :from_discord do
      description("Create channel from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: true,
        description: "Discord channel struct to transform"
      )

      argument(:discord_id, :integer,
        allow_nil?: true,
        description: "Discord channel ID for API fallback"
      )

      change({AshDiscord.Changes.FromDiscord, type: :channel})

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :name,
        :type,
        :position,
        :topic,
        :nsfw,
        :parent_id,
        :permission_overwrites,
        :guild_id
      ])
    end

    update :update do
      primary?(true)

      accept([
        :name,
        :type,
        :position,
        :topic,
        :nsfw,
        :parent_id,
        :permission_overwrites,
        :guild_id
      ])
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:read)
  end
end
