defmodule TestApp.Discord.MessagePollVote do
  @moduledoc """
  Test Discord MessagePollVote resource for validating poll vote transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:message_poll_vote)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:user_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:message_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:answer_id, :integer,
      allow_nil?: false,
      public?: true
    )

    timestamps()
  end

  relationships do
    belongs_to :user, TestApp.Discord.User do
      source_attribute(:user_discord_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :message, TestApp.Discord.Message do
      source_attribute(:message_discord_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :channel, TestApp.Discord.Channel do
      source_attribute(:channel_discord_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :guild, TestApp.Discord.Guild do
      source_attribute(:guild_discord_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end
  end

  identities do
    # Unique combination of user, message, and answer
    identity :unique_vote, [:user_discord_id, :message_discord_id, :answer_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
    define(:message_poll_vote_from_discord, action: :from_discord)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create message poll vote from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.PollVoteChangeEvent,
        allow_nil?: false,
        description: "Discord message poll vote event data"
      )

      change(AshDiscord.Changes.FromDiscord.MessagePollVote)

      upsert?(true)
      upsert_identity(:unique_vote)

      upsert_fields([
        :channel_discord_id,
        :guild_discord_id
      ])
    end

    update :update do
      primary?(true)

      accept([
        :user_discord_id,
        :message_discord_id,
        :channel_discord_id,
        :guild_discord_id,
        :answer_id
      ])
    end
  end
end
