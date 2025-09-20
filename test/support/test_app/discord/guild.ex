defmodule TestApp.Discord.Guild do
  @moduledoc """
  Test Guild resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:name, :string, allow_nil?: false, public?: true)
    attribute(:description, :string, public?: true)
    attribute(:icon, :string, public?: true)

    timestamps()
  end

  identities do
    identity(:unique_discord_id, [:discord_id], pre_check_with: TestApp.Domain)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:discord_id, :name, :description, :icon])
    end

    create :from_discord do
      accept([:discord_id, :name, :description, :icon])
      upsert?(true)
      upsert_identity(:unique_discord_id)
      upsert_fields([:name, :description, :icon])

      argument(:discord_struct, :map,
        allow_nil?: true,
        description: "Discord guild data to transform"
      )

      argument(:discord_id, :integer,
        allow_nil?: true,
        description: "Discord guild ID for API fallback"
      )

      change({AshDiscord.Changes.FromDiscord, type: :guild})
    end

    update :update do
      primary?(true)
      accept([:name, :description, :icon])
    end

    update :configure do
      accept([:name, :description])
      require_atomic?(false)

      argument(:setting, :string, allow_nil?: false)
      argument(:enabled, :boolean, allow_nil?: false)

      change(fn changeset, _context ->
        setting = Ash.Changeset.get_argument(changeset, :setting)
        enabled = Ash.Changeset.get_argument(changeset, :enabled)

        new_description = "Configured #{setting}: #{enabled}"
        Ash.Changeset.change_attribute(changeset, :description, new_description)
      end)
    end
  end

  relationships do
    has_many(:messages, TestApp.Discord.Message,
      destination_attribute: :guild_id,
      source_attribute: :discord_id
    )
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:configure)
    define(:read)
  end
end
