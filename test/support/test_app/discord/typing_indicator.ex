defmodule TestApp.Discord.TypingIndicator do
  @moduledoc """
  Test Discord TypingIndicator resource for validating typing indicator transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:typing_indicator)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:user_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:timestamp, :utc_datetime,
      allow_nil?: true,
      public?: true
    )
  end

  identities do
    identity :discord_id, [:user_id, :channel_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create typing indicator from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.TypingStartEvent,
        allow_nil?: true,
        description: "Discord typing indicator TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.TypingIndicator)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:guild_id, :timestamp])
    end

    update :update do
      primary?(true)
      accept([:guild_id, :timestamp])
    end
  end
end
