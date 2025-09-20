defmodule AshDiscord.Changes.FromDiscord do
  @moduledoc """
  Configurable change for creating resources from Discord data with type-based dispatch.

  This change module supports transforming Discord entities into Ash resource attributes
  based on the specified entity type. It follows a struct-first pattern where Discord
  data is provided via the `:discord_struct` argument, with API fallback capabilities.

  ## Usage

      actions do
        create :from_discord do
          argument :discord_struct, :map,
            description: "Discord entity struct to transform"

          change {AshDiscord.Changes.FromDiscord, type: :user}
        end
      end

  ## Supported Types

  The change supports all Discord entity types discovered in the codebase:
  - `:user` - Discord users with username, avatar, email generation
  - `:guild` - Discord guilds/servers with name, description, icon
  - `:guild_member` - Guild membership with roles, datetime parsing
  - `:role` - Guild roles with permissions and color
  - `:channel` - Text/voice channels with permission overwrites
  - `:message` - Chat messages with content and attachments
  - `:emoji` - Custom guild emojis
  - `:voice_state` - Voice channel connection state
  - `:webhook` - Channel webhooks
  - `:invite` - Guild/channel invites
  - `:message_attachment` - Message file attachments
  - `:message_reaction` - Message reactions
  - `:typing_indicator` - Typing status indicators
  - `:sticker` - Guild stickers
  - `:interaction` - Slash command interactions

  ## Data Flow

  1. **Struct-first**: Primary data source is `:discord_struct` argument
  2. **API fallback**: If no struct provided, attempts API fetch using Discord ID
  3. **Type dispatch**: Routes to appropriate transformation function based on type
  4. **Relationship management**: Handles related entities with auto-creation patterns

  ## Example

      # Create user from Discord struct
      MyApp.Discord.User.from_discord(%{
        discord_struct: %Nostrum.Struct.User{
          id: 123456789,
          username: "testuser",
          avatar: "avatar_hash"
        }
      })

  """
  use Ash.Resource.Change

  @supported_types [
    :user,
    :guild,
    :guild_member,
    :role,
    :channel,
    :message,
    :emoji,
    :voice_state,
    :webhook,
    :invite,
    :message_attachment,
    :message_reaction,
    :typing_indicator,
    :sticker,
    :interaction
  ]

  @impl true
  def init(opts) do
    case Keyword.fetch(opts, :type) do
      {:ok, type} ->
        unless type in @supported_types do
          raise ArgumentError, """
          Invalid Discord entity type: #{inspect(type)}

          Supported types: #{inspect(@supported_types)}
          """
        end

        {:ok, [type: type]}

      :error ->
        raise KeyError, "type option is required"
    end
  end

  @impl true
  def change(changeset, opts, _context) do
    type = Keyword.fetch!(opts, :type)

    case get_discord_data(changeset, type) do
      {:ok, discord_data} ->
        transform_entity(changeset, type, discord_data)

      {:error, reason} ->
        Ash.Changeset.add_error(changeset, reason)
    end
  end

  # Data retrieval with struct-first pattern
  defp get_discord_data(changeset, type) do
    case Ash.Changeset.get_argument(changeset, :discord_struct) do
      nil ->
        # Fallback to API fetch (placeholder for now)
        AshDiscord.Changes.FromDiscord.ApiFetchers.fetch_from_api(changeset, type)

      discord_struct when is_map(discord_struct) ->
        {:ok, discord_struct}

      invalid ->
        {:error, "Invalid discord_struct format: expected map, got #{inspect(invalid)}"}
    end
  end

  # Type-based dispatch to transformation functions
  defp transform_entity(changeset, :user, discord_data),
    do: transform_user(changeset, discord_data)

  defp transform_entity(changeset, :guild, discord_data),
    do: transform_guild(changeset, discord_data)

  defp transform_entity(changeset, :guild_member, discord_data),
    do: transform_guild_member(changeset, discord_data)

  defp transform_entity(changeset, :role, discord_data),
    do: transform_role(changeset, discord_data)

  defp transform_entity(changeset, :channel, discord_data),
    do: transform_channel(changeset, discord_data)

  defp transform_entity(changeset, :message, discord_data),
    do: transform_message(changeset, discord_data)

  defp transform_entity(changeset, :emoji, discord_data),
    do: transform_emoji(changeset, discord_data)

  defp transform_entity(changeset, :voice_state, discord_data),
    do: transform_voice_state(changeset, discord_data)

  defp transform_entity(changeset, :webhook, discord_data),
    do: transform_webhook(changeset, discord_data)

  defp transform_entity(changeset, :invite, discord_data),
    do: transform_invite(changeset, discord_data)

  defp transform_entity(changeset, :message_attachment, discord_data),
    do: transform_message_attachment(changeset, discord_data)

  defp transform_entity(changeset, :message_reaction, discord_data),
    do: transform_message_reaction(changeset, discord_data)

  defp transform_entity(changeset, :typing_indicator, discord_data),
    do: transform_typing_indicator(changeset, discord_data)

  defp transform_entity(changeset, :sticker, discord_data),
    do: transform_sticker(changeset, discord_data)

  defp transform_entity(changeset, :interaction, discord_data),
    do: transform_interaction(changeset, discord_data)

  defp transform_entity(_changeset, type, _discord_data) do
    raise "Unsupported Discord entity type: #{type}. This should not happen if init/1 validation is working."
  end

  # Transformation functions (to be implemented in subsequent tasks)
  # These are placeholders that will be implemented following the breakdown

  defp transform_user(changeset, _discord_data) do
    # TODO: Implement user transformation following steward patterns
    changeset
  end

  defp transform_guild(changeset, _discord_data) do
    # TODO: Implement guild transformation following steward patterns
    changeset
  end

  defp transform_guild_member(changeset, _discord_data) do
    # TODO: Implement guild member transformation with datetime parsing
    changeset
  end

  defp transform_role(changeset, _discord_data) do
    # TODO: Implement role transformation with permissions handling
    changeset
  end

  defp transform_channel(changeset, _discord_data) do
    # TODO: Implement channel transformation with permission overwrites
    changeset
  end

  defp transform_message(changeset, _discord_data) do
    # TODO: Implement message transformation with attachments
    changeset
  end

  defp transform_emoji(changeset, _discord_data) do
    # TODO: Implement emoji transformation with guild relationship
    changeset
  end

  defp transform_voice_state(changeset, _discord_data) do
    # TODO: Implement voice state transformation with boolean fields
    changeset
  end

  defp transform_webhook(changeset, _discord_data) do
    # TODO: Implement webhook transformation
    changeset
  end

  defp transform_invite(changeset, _discord_data) do
    # TODO: Implement invite transformation with relationships
    changeset
  end

  defp transform_message_attachment(changeset, _discord_data) do
    # TODO: Implement attachment transformation
    changeset
  end

  defp transform_message_reaction(changeset, _discord_data) do
    # TODO: Implement reaction transformation
    changeset
  end

  defp transform_typing_indicator(changeset, _discord_data) do
    # TODO: Implement typing indicator transformation
    changeset
  end

  defp transform_sticker(changeset, _discord_data) do
    # TODO: Implement sticker transformation
    changeset
  end

  defp transform_interaction(changeset, _discord_data) do
    # TODO: Implement interaction transformation
    changeset
  end
end
