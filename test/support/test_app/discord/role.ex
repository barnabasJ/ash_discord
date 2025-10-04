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

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create role from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.Role,
        allow_nil?: true,
        description: "Discord role TypedStruct data"
      )

      argument(:identity, :map,
        allow_nil?: true,
        description: "Map with guild_id and role_id for API fallback"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :identity) do
          %{guild_id: guild_id} ->
            Ash.Changeset.force_change_attribute(changeset, :guild_id, guild_id)

          _ ->
            changeset
        end
      end)

      change(AshDiscord.Changes.FromDiscord.Role)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :guild_id,
        :name,
        :color,
        :permissions,
        :hoist,
        :position,
        :managed,
        :mentionable
      ])
    end

    update :update do
      primary?(true)
      accept([:guild_id, :name, :color, :permissions, :hoist, :position, :managed, :mentionable])
    end
  end
end
