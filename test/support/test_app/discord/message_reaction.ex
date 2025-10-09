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
    identity(:discord_id, [:user_discord_id, :message_discord_id, :guild_discord_id, :emoji_name],
      pre_check_with: TestApp.Domain
    )
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

      argument(:identity, :map,
        allow_nil?: true,
        description:
          "Map with channel_id, message_id, emoji_name, emoji_id (optional), and user_discord_id for API fallback"
      )

      # Set identity fields BEFORE the main change module runs - required for upsert matching
      change(fn changeset, _context ->
        identity = Ash.Changeset.get_argument(changeset, :identity)
        data = Ash.Changeset.get_argument(changeset, :data)

        # Set user_discord_id from identity or data
        changeset =
          case {identity, data} do
            {%{user_discord_id: user_discord_id}, _} when not is_nil(user_discord_id) ->
              Ash.Changeset.force_change_attribute(changeset, :user_discord_id, user_discord_id)

            {_, %{user_id: user_id}} when not is_nil(user_id) ->
              Ash.Changeset.force_change_attribute(changeset, :user_discord_id, user_id)

            _ ->
              changeset
          end

        # Set message_discord_id from identity or data
        changeset =
          case {identity, data} do
            {%{message_discord_id: message_discord_id}, _} when not is_nil(message_discord_id) ->
              Ash.Changeset.force_change_attribute(
                changeset,
                :message_discord_id,
                message_discord_id
              )

            {_, %{message_id: message_id}} when not is_nil(message_id) ->
              Ash.Changeset.force_change_attribute(changeset, :message_discord_id, message_id)

            _ ->
              changeset
          end

        # Set guild_discord_id from identity or data - always set even if nil
        guild_discord_id =
          case {identity, data} do
            {%{guild_discord_id: guild_discord_id}, _} -> guild_discord_id
            {_, %{guild_id: guild_id}} -> guild_id
            _ -> nil
          end

        changeset =
          Ash.Changeset.force_change_attribute(changeset, :guild_discord_id, guild_discord_id)

        # Set emoji_name from identity or data
        changeset =
          case {identity, data} do
            {%{emoji_name: emoji_name}, _} when not is_nil(emoji_name) ->
              Ash.Changeset.force_change_attribute(changeset, :emoji_name, emoji_name)

            {_, %{emoji: emoji}} when not is_nil(emoji) ->
              emoji_name = Map.get(emoji, :name)
              Ash.Changeset.force_change_attribute(changeset, :emoji_name, emoji_name)

            _ ->
              changeset
          end

        # Set emoji_id from identity or data - always set even if nil
        emoji_id =
          case {identity, data} do
            {%{emoji_id: emoji_id}, _} ->
              emoji_id

            {_, %{emoji: emoji}} when not is_nil(emoji) ->
              Map.get(emoji, :id)

            _ ->
              nil
          end

        Ash.Changeset.force_change_attribute(changeset, :emoji_id, emoji_id)
      end)

      change(AshDiscord.Changes.FromDiscord.MessageReaction)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :emoji_id,
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

    update :update do
      primary?(true)

      accept([
        :emoji_id,
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
