defmodule TestApp.Discord.Integration do
  @moduledoc """
  Test Discord Integration resource for validating integration transformations.
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

    attribute(:guild_id, :integer,
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

    attribute(:account_id, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:account_name, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:application_name, :string,
      allow_nil?: true,
      public?: true
    )
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
        allow_nil?: true,
        description: "Discord integration TypedStruct data"
      )

      argument(:identity, :map,
        allow_nil?: true,
        description: "Map with guild_id and integration_id for API fallback"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :identity) do
          %{guild_id: guild_id} ->
            Ash.Changeset.force_change_attribute(changeset, :guild_id, guild_id)

          _ ->
            changeset
        end
      end)

      change(AshDiscord.Changes.FromDiscord.Integration)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :guild_id,
        :name,
        :type,
        :enabled,
        :account_id,
        :account_name,
        :application_id,
        :application_name
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_id,
        :name,
        :type,
        :enabled,
        :account_id,
        :account_name,
        :application_id,
        :application_name
      ])
    end
  end
end
