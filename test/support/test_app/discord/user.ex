defmodule TestApp.Discord.User do
  @moduledoc """
  Test User resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "discord_users"
    repo(TestApp.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :discord_id, :integer, allow_nil?: false, public?: true
    attribute :username, :string, allow_nil?: false, public?: true
    attribute :discriminator, :string, public?: true
    attribute :avatar, :string, public?: true
    attribute :email, :string, public?: true

    timestamps()
  end

  identities do
    identity :unique_discord_id, [:discord_id]
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:discord_id, :username, :discriminator, :avatar, :email]
    end

    create :from_discord do
      accept [:discord_id, :username, :discriminator, :avatar, :email]
      upsert? true
      upsert_identity :unique_discord_id
      upsert_fields [:username, :discriminator, :avatar, :email]

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :discord_id) do
          nil ->
            changeset

          discord_id ->
            # If username is not provided, use mock data
            changeset =
              if Ash.Changeset.get_attribute(changeset, :username) do
                changeset
              else
                Ash.Changeset.change_attribute(changeset, :username, "testuser#{discord_id}")
              end

            # If discriminator is not provided, use mock data
            changeset =
              if Ash.Changeset.get_attribute(changeset, :discriminator) do
                changeset
              else
                Ash.Changeset.change_attribute(changeset, :discriminator, "0001")
              end

            changeset
        end
      end
    end

    update :update do
      primary? true
      accept [:username, :discriminator, :avatar, :email]
    end

    update :ban do
      require_atomic? false
      
      argument :user, :string, allow_nil?: false
      argument :reason, :string, allow_nil?: true

      change fn changeset, _context ->
        # Mock implementation for testing - in reality would involve Discord API calls
        user = Ash.Changeset.get_argument(changeset, :user)
        reason = Ash.Changeset.get_argument(changeset, :reason) || "No reason provided"
        
        # Log the ban action for testing
        Process.put(:ban_executed, %{user: user, reason: reason})
        
        changeset
      end
    end
  end

  relationships do
    has_many :messages, TestApp.Discord.Message,
      destination_attribute: :author_id,
      source_attribute: :discord_id
  end

  code_interface do
    define :create
    define :from_discord
    define :update
    define :ban
    define :read
  end

  @doc """
  Helper to create Discord-formatted struct for testing.
  """
  def discord_struct(attrs) do
    %{
      id: Map.get(attrs, :discord_id),
      username: Map.get(attrs, :username),
      discriminator: Map.get(attrs, :discriminator),
      avatar: Map.get(attrs, :avatar),
      email: Map.get(attrs, :email),
      bot: Map.get(attrs, :bot, false),
      global_name: Map.get(attrs, :display_name)
    }
  end
end
