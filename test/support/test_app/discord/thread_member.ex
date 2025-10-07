defmodule TestApp.Discord.ThreadMember do
  @moduledoc """
  Test Discord ThreadMember resource for validating thread member transformations.

  Thread members represent a user's membership in a specific thread.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:thread_member)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:thread_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:flags, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:join_timestamp, :utc_datetime,
      allow_nil?: false,
      public?: true
    )
  end

  identities do
    identity :thread_user, [:thread_discord_id, :user_discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :thread_discord_id,
        :user_discord_id,
        :guild_discord_id,
        :flags,
        :join_timestamp
      ])
    end

    create :from_discord do
      description("Create thread member from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.ThreadMember,
        allow_nil?: false,
        description: "Discord thread member TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.ThreadMember)

      upsert?(true)
      upsert_identity(:thread_user)

      upsert_fields([
        :guild_discord_id,
        :flags,
        :join_timestamp
      ])
    end

    update :update do
      primary?(true)

      accept([
        :guild_discord_id,
        :flags,
        :join_timestamp
      ])
    end
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:update)
    define(:read)
  end
end
