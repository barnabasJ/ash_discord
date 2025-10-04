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
    attribute(:premium_since, :utc_datetime, public?: true)
    attribute(:deaf, :boolean, public?: true, default: false)
    attribute(:mute, :boolean, public?: true, default: false)
    attribute(:pending, :boolean, public?: true, default: false)
    attribute(:avatar, :string, public?: true)
    attribute(:communication_disabled_until, :utc_datetime, public?: true)

    timestamps()
  end

  identities do
    identity(:unique_member, [:guild_id, :user_id], pre_check_with: TestApp.Domain)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:guild_id, :user_id, :nick, :roles, :joined_at])
    end

    create :from_discord do
      upsert?(true)
      upsert_identity(:unique_member)

      upsert_fields([
        :nick,
        :roles,
        :joined_at,
        :premium_since,
        :deaf,
        :mute,
        :pending,
        :avatar,
        :communication_disabled_until
      ])

      argument(:data, AshDiscord.Consumer.Payloads.Member,
        allow_nil?: true,
        description: "Discord guild member TypedStruct payload"
      )

      argument(:identity, :map,
        allow_nil?: true,
        description: "Map with guild_id and user_id for API fallback"
      )

      change(fn changeset, _context ->
        # Set guild_id and user_id from identity or data
        identity = Ash.Changeset.get_argument(changeset, :identity)
        data = Ash.Changeset.get_argument(changeset, :data)

        changeset =
          case {identity, data} do
            {%{guild_id: guild_id}, _} when not is_nil(guild_id) ->
              Ash.Changeset.force_change_attribute(changeset, :guild_id, guild_id)

            _ ->
              changeset
          end

        case data do
          %{user_id: user_id} when not is_nil(user_id) ->
            Ash.Changeset.force_change_attribute(changeset, :user_id, user_id)

          _ ->
            changeset
        end
      end)

      change(AshDiscord.Changes.FromDiscord.GuildMember)
    end

    update :update do
      primary?(true)
      accept([:nick, :roles, :joined_at])
    end
  end

  relationships do
    # TODO: use the regular ids
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
