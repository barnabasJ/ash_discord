defmodule TestApp.Discord.MessageReaction do
  @moduledoc """
  Test Discord MessageReaction resource for validating reaction transformations.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:emoji_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:emoji_name, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:count, :integer,
      allow_nil?: false,
      public?: true,
      default: 1
    )

    attribute(:me, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:emoji_animated, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    # Foreign key attributes for relationships
    attribute(:user_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:message_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )
  end

  relationships do
    belongs_to :user, TestApp.Discord.User do
      source_attribute(:user_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :message, TestApp.Discord.Message do
      source_attribute(:message_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :channel, TestApp.Discord.Channel do
      source_attribute(:channel_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end

    belongs_to :guild, TestApp.Discord.Guild do
      source_attribute(:guild_id)
      destination_attribute(:discord_id)
      allow_nil?(true)
    end
  end

  identities do
    # Use user_id, message_id, and either emoji_id (for custom) or emoji_name (for standard)
    # We'll exclude emoji_id from the identity and handle uniqueness through a combination
    identity :reaction_identity, [:user_id, :message_id, :emoji_name] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create message reaction from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.MessageReactionAddEvent,
        allow_nil?: true,
        description: "Discord message reaction TypedStruct data"
      )

      change(AshDiscord.Changes.FromDiscord.MessageReaction)

      upsert?(true)
      upsert_identity(:reaction_identity)

      upsert_fields([
        :emoji_id,
        :emoji_name,
        :count,
        :me,
        :emoji_animated,
        :user_id,
        :message_id,
        :channel_id,
        :guild_id
      ])
    end

    update :update do
      primary?(true)

      accept([
        :emoji_id,
        :emoji_name,
        :count,
        :me,
        :emoji_animated,
        :user_id,
        :message_id,
        :channel_id,
        :guild_id
      ])
    end
  end
end
