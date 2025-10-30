defmodule TestApp.Discord.ChannelPinsUpdate do
  @moduledoc """
  Test Discord ChannelPinsUpdate resource for validating channel pins update transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    events do
      on(:CHANNEL_PINS_UPDATE, :from_discord)
    end
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:channel_discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "The ID of the channel where pins were updated"
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true,
      description: "The ID of the guild (if in a guild channel)"
    )

    attribute(:last_pin_timestamp, :utc_datetime,
      allow_nil?: true,
      public?: true,
      description: "The timestamp of the most recent pinned message"
    )
  end

  identities do
    identity(:channel_discord_id, [:channel_discord_id], pre_check_with: TestApp.Discord)
  end

  code_interface do
    define(:read)
  end

  relationships do
    belongs_to :guild, TestApp.Discord.Guild do
      description("The guild this channel pins update belongs to")
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:guild_discord_id)
    end

    belongs_to :channel, TestApp.Discord.Channel do
      public?(true)
      destination_attribute(:discord_id)
      source_attribute(:channel_discord_id)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create channel pins update from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent,
        allow_nil?: true,
        description: "Discord channel pins update TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.ChannelPinsUpdate)

      upsert?(true)
      upsert_identity(:channel_discord_id)
      upsert_fields([:guild_discord_id, :last_pin_timestamp])
    end

    update :update do
      primary?(true)
      accept([:channel_discord_id, :guild_discord_id, :last_pin_timestamp])
    end
  end
end
