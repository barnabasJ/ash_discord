defmodule TestApp.Discord.Guild do
  @moduledoc """
  Test Guild resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "discord_guilds"
    repo(TestApp.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :discord_id, :integer, allow_nil?: false, public?: true
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, public?: true
    attribute :icon, :string, public?: true

    timestamps()
  end

  identities do
    identity :unique_discord_id, [:discord_id]
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:discord_id, :name, :description, :icon]
    end

    create :from_discord do
      accept [:discord_id, :name, :description, :icon]
      upsert? true
      upsert_identity :unique_discord_id
      upsert_fields [:name, :description, :icon]

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :discord_id) do
          nil ->
            changeset

          discord_id ->
            # If name is not provided, use mock data
            changeset =
              if Ash.Changeset.get_attribute(changeset, :name) do
                changeset
              else
                Ash.Changeset.change_attribute(changeset, :name, "Test Guild #{discord_id}")
              end

            # If description is not provided, use mock data
            changeset =
              if Ash.Changeset.get_attribute(changeset, :description) do
                changeset
              else
                Ash.Changeset.change_attribute(changeset, :description, "A test guild")
              end

            changeset
        end
      end
    end

    update :update do
      primary? true
      accept [:name, :description, :icon]
    end

    update :configure do
      accept [:name, :description]
      require_atomic? false

      argument :setting, :string, allow_nil?: false
      argument :enabled, :boolean, allow_nil?: false

      change fn changeset, _context ->
        setting = Ash.Changeset.get_argument(changeset, :setting)
        enabled = Ash.Changeset.get_argument(changeset, :enabled)

        new_description = "Configured #{setting}: #{enabled}"
        Ash.Changeset.change_attribute(changeset, :description, new_description)
      end
    end
  end

  relationships do
    has_many :messages, TestApp.Discord.Message,
      destination_attribute: :guild_id,
      source_attribute: :discord_id
  end

  code_interface do
    define :create
    define :from_discord
    define :configure
    define :read
  end

  @doc """
  Helper to create Discord-formatted struct for testing.
  """
  def discord_struct(attrs) do
    %{
      id: Map.get(attrs, :discord_id),
      name: Map.get(attrs, :name),
      description: Map.get(attrs, :description),
      icon: Map.get(attrs, :icon)
    }
  end
end
