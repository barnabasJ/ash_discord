defmodule TestApp.Discord.ThreadListSync do
  @moduledoc """
  Test Discord ThreadListSync resource for tracking thread synchronization events.

  This is a trace resource that records when thread list sync events occur,
  primarily for verification that the handler executed correctly.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    events do
      on(:THREAD_LIST_SYNC, :from_discord)
    end
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_ids, {:array, :integer},
      allow_nil?: true,
      public?: true,
      default: []
    )

    attribute(:threads, {:array, :map},
      allow_nil?: true,
      public?: true,
      default: []
    )

    attribute(:members, {:array, :map},
      allow_nil?: true,
      public?: true,
      default: []
    )

    create_timestamp(:inserted_at)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :guild_discord_id,
        :channel_ids,
        :threads,
        :members
      ])
    end

    create :from_discord do
      description("Create thread list sync record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.ThreadListSyncEvent,
        allow_nil?: false,
        description: "Discord thread list sync TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.ThreadListSync)
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:read)
  end
end
