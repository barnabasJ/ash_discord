defmodule TestApp.Discord.ThreadMembersUpdate do
  @moduledoc """
  Test Discord ThreadMembersUpdate resource for tracking thread member change events.

  This is a trace resource that records when thread members are added or removed,
  primarily for verification that the handler executed correctly.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:thread_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:member_count, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:added_members, {:array, :map},
      allow_nil?: true,
      public?: true,
      default: []
    )

    attribute(:removed_member_ids, {:array, :integer},
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
        :thread_discord_id,
        :guild_discord_id,
        :member_count,
        :added_members,
        :removed_member_ids
      ])
    end

    create :from_discord do
      description("Create thread members update record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent,
        allow_nil?: false,
        description: "Discord thread members update TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.ThreadMembersUpdate)
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:read)
  end
end
