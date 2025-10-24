defmodule TestApp.Discord.GuildScheduledEventUser do
  @moduledoc """
  Test GuildScheduledEventUser resource for AshDiscord testing.

  This resource tracks user subscriptions to scheduled events. It's primarily
  used for tracing handler execution for informational events (USER_ADD/USER_REMOVE).
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    events do
      on(:GUILD_SCHEDULED_EVENT_USER_ADD, :from_discord)
      on(:GUILD_SCHEDULED_EVENT_USER_REMOVE, :destroy)
    end
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:event_discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:user_discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:guild_discord_id, :integer, allow_nil?: false, public?: true)

    timestamps()
  end

  identities do
    identity(:discord_id, [:event_discord_id, :user_discord_id], pre_check_with: TestApp.Discord)
  end

  relationships do
    belongs_to :guild_scheduled_event, TestApp.Discord.GuildScheduledEvent do
      source_attribute(:event_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :user, TestApp.Discord.User do
      source_attribute(:user_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :guild, TestApp.Discord.Guild do
      source_attribute(:guild_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create guild scheduled event user subscription from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.GuildScheduledEventUserAdd,
        allow_nil?: false,
        description: "Discord guild scheduled event user add payload"
      )

      change(AshDiscord.Changes.FromDiscord.GuildScheduledEventUser)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:guild_discord_id])
    end

    update :update do
      primary?(true)
      accept([])
    end
  end

  code_interface do
    define(:from_discord)
    define(:update)
    define(:read)
    define(:destroy)
  end
end
