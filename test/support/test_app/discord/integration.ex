defmodule TestApp.Discord.Integration do
  @moduledoc """
  Test Discord Integration resource for validating integration transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:integration)
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

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:name, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:type, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:enabled, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:account_discord_id, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:account_name, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_name, :string,
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
      description("Create integration from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Integration,
        allow_nil?: false,
        description: "Discord integration TypedStruct data (required - no API fallback)"
      )

      change(AshDiscord.Changes.FromDiscord.Integration)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :guild_discord_id,
        :name,
        :type,
        :enabled,
        :account_discord_id,
        :account_name,
        :application_discord_id,
        :application_name
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_discord_id,
        :name,
        :type,
        :enabled,
        :account_discord_id,
        :account_name,
        :application_discord_id,
        :application_name
      ])
    end
  end
end
