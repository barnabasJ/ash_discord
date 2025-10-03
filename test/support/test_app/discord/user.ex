defmodule TestApp.Discord.User do
  @moduledoc """
  Test User resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:discord_username, :string, allow_nil?: false, public?: true)
    attribute(:discriminator, :string, public?: true)
    attribute(:discord_avatar, :string, public?: true)
    attribute(:email, :string, public?: true)

    timestamps()
  end

  identities do
    identity(:discord_id, [:discord_id], pre_check_with: TestApp.Domain)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:discord_id, :discord_username, :discriminator, :discord_avatar, :email])
    end

    create :from_discord do
      description("Create or update a user from Discord API data or struct")

      accept([:discord_id])

      argument(:data, AshDiscord.Consumer.Payloads.User,
        allow_nil?: true,
        description: "Discord user TypedStruct payload"
      )

      argument(:identity, :integer,
        allow_nil?: true,
        description: "Discord user ID for API fallback"
      )

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:discord_username, :discord_avatar])

      change(AshDiscord.Changes.FromDiscord.User)
    end

    update :update do
      primary?(true)
      accept([:discord_username, :discriminator, :discord_avatar, :email])
    end

    update :ban do
      require_atomic?(false)

      argument(:user, :string, allow_nil?: false)
      argument(:reason, :string, allow_nil?: true)

      change(fn changeset, _context ->
        # Mock implementation for testing - in reality would involve Discord API calls
        user = Ash.Changeset.get_argument(changeset, :user)
        reason = Ash.Changeset.get_argument(changeset, :reason) || "No reason provided"

        # Log the ban action for testing
        Process.put(:ban_executed, %{user: user, reason: reason})

        changeset
      end)
    end
  end

  relationships do
    has_many(:messages, TestApp.Discord.Message,
      destination_attribute: :author_id,
      source_attribute: :discord_id
    )
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:ban)
    define(:read)
  end
end
