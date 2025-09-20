defmodule TestApp.Discord.GuildMember do
  @moduledoc """
  Test GuildMember resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_id, :integer, allow_nil?: false, public?: true)
    attribute(:user_id, :integer, allow_nil?: false, public?: true)
    attribute(:nick, :string, public?: true)
    attribute(:roles, {:array, :integer}, public?: true, default: [])
    attribute(:joined_at, :utc_datetime, public?: true)

    timestamps()
  end

  identities do
    identity(:unique_member, [:guild_id, :user_id], pre_check_with: TestApp.Domain)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:guild_id, :user_id, :nick, :roles, :joined_at])
    end

    create :from_discord do
      accept([:guild_id, :user_id, :nick, :roles, :joined_at])
      upsert?(true)
      upsert_identity(:unique_member)
      upsert_fields([:nick, :roles, :joined_at])

      change(fn changeset, _context ->
        # Mock data for testing
        guild_id = Ash.Changeset.get_attribute(changeset, :guild_id)
        user_id = Ash.Changeset.get_attribute(changeset, :user_id)

        changeset =
          if is_nil(Ash.Changeset.get_attribute(changeset, :joined_at)) do
            Ash.Changeset.change_attribute(changeset, :joined_at, DateTime.utc_now())
          else
            changeset
          end

        changeset =
          if is_nil(Ash.Changeset.get_attribute(changeset, :nick)) do
            Ash.Changeset.change_attribute(changeset, :nick, "Member #{user_id}")
          else
            changeset
          end

        changeset
      end)
    end

    update :update do
      primary?(true)
      accept([:nick, :roles, :joined_at])
    end
  end

  relationships do
    belongs_to(:guild, TestApp.Discord.Guild,
      destination_attribute: :discord_id,
      source_attribute: :guild_id
    )

    belongs_to(:user, TestApp.Discord.User,
      destination_attribute: :discord_id,
      source_attribute: :user_id
    )
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:read)
  end
end
