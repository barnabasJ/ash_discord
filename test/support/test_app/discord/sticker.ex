defmodule TestApp.Discord.Sticker do
  @moduledoc """
  Test Discord Sticker resource for validating sticker transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:sticker)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:pack_discord_id, :integer,
      allow_nil?: true,
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

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:sort_value, :integer,
      allow_nil?: true,
      public?: true
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
    identity :discord_id, [:discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
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

      upsert_fields([
        :pack_discord_id,
        :name,
        :description,
        :tags,
        :type,
        :format_type,
        :available,
        :guild_discord_id,
        :user_discord_id,
        :sort_value
      ])
    end

    update :update do
      primary?(true)

      accept([
        :pack_discord_id,
        :name,
        :description,
        :tags,
        :type,
        :format_type,
        :available,
        :guild_discord_id,
        :user_discord_id,
        :sort_value
      ])
    end
  end
end
