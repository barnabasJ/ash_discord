defmodule TestApp.Discord.MessageReaction do
  @moduledoc """
  Test Discord MessageReaction resource for validating reaction transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:message_reaction)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

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
    attribute(:emoji_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:emoji_name, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:user_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:message_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:channel_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: true,
      public?: true
    )
  end

  relationships do
    has_one :emoji, TestApp.Discord.Emoji do
      no_attributes?(true)
      filter(expr(discord_id == ^parent(:emoji_discord_id) and name == ^parent(:emoji_name)))
    end

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
    # Use user_discord_id, message_discord_id, guild_discord_id, and emoji_name for identity
    # emoji_id is excluded because it's nil for Unicode emojis but not for custom emojis
    # emoji_name is sufficient to identify the emoji uniquely
    identity :discord_id, [
      :user_discord_id,
      :message_discord_id,
      :guild_discord_id,
      :channel_discord_id,
      :emoji_name,
      :emoji_discord_id
    ] do
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
      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :emoji_discord_id,
        :emoji_name,
        :count,
        :me,
        :emoji_animated,
        :user_discord_id,
        :message_discord_id,
        :channel_discord_id,
        :guild_discord_id
      ])

      argument(:data, AshDiscord.Consumer.Payloads.MessageReactionAddEvent,
        allow_nil?: true,
        description: "Discord message reaction TypedStruct data"
      )

      argument(:identity, :map,
        allow_nil?: true,
        description:
          "Map with channel_id, message_id, emoji_name, emoji_id (optional), and user_discord_id for API fallback"
      )

      change(AshDiscord.Changes.FromDiscord.MessageReaction)
    end

    update :update do
      primary?(true)

      accept([
        :emoji_discord_id,
        :emoji_name,
        :count,
        :me,
        :emoji_animated,
        :user_discord_id,
        :message_discord_id,
        :channel_discord_id,
        :guild_discord_id
      ])
    end
  end
end
