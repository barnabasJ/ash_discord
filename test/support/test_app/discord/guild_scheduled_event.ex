defmodule TestApp.Discord.GuildScheduledEvent do
  @moduledoc """
  Test GuildScheduledEvent resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:guild_id, :integer, allow_nil?: false, public?: true)
    attribute(:channel_id, :integer, public?: true)
    attribute(:creator_id, :integer, public?: true)
    attribute(:name, :string, allow_nil?: false, public?: true)
    attribute(:description, :string, public?: true)
    attribute(:scheduled_start_time, :utc_datetime, allow_nil?: false, public?: true)
    attribute(:scheduled_end_time, :utc_datetime, public?: true)
    attribute(:privacy_level, :integer, allow_nil?: false, public?: true)
    attribute(:status, :integer, allow_nil?: false, public?: true)
    attribute(:entity_type, :integer, allow_nil?: false, public?: true)
    attribute(:entity_id, :integer, public?: true)
    attribute(:entity_metadata_location, :string, public?: true)
    attribute(:user_count, :integer, public?: true)

    timestamps()
  end

  identities do
    identity(:discord_id, [:discord_id], pre_check_with: TestApp.Discord)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)

      accept([
        :discord_id,
        :guild_id,
        :name,
        :scheduled_start_time,
        :privacy_level,
        :status,
        :entity_type
      ])
    end

    create :from_discord do
      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :guild_id,
        :channel_id,
        :creator_id,
        :name,
        :description,
        :scheduled_start_time,
        :scheduled_end_time,
        :privacy_level,
        :status,
        :entity_type,
        :entity_id,
        :entity_metadata_location,
        :user_count
      ])

      argument(:data, AshDiscord.Consumer.Payloads.GuildScheduledEvent,
        allow_nil?: false,
        description: "Discord guild scheduled event TypedStruct payload"
      )

      change(AshDiscord.Changes.FromDiscord.GuildScheduledEvent)
    end

    update :update do
      primary?(true)
      accept([:name, :description, :scheduled_start_time, :scheduled_end_time, :status])
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:read)
  end
end
