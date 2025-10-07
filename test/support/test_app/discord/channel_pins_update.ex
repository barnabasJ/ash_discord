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

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "The Discord channel ID (used as identity)"
    )

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "The ID of the channel where pins were updated"
    )

    attribute(:guild_id, :integer,
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
      description("Create channel pins update from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent,
        allow_nil?: true,
        description: "Discord channel pins update TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.ChannelPinsUpdate)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:channel_id, :guild_id, :last_pin_timestamp])
    end

    update :update do
      primary?(true)
      accept([:channel_id, :guild_id, :last_pin_timestamp])
    end
  end
end
