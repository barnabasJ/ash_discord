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

  alias AshDiscord.Changes.FromDiscord.Transformations

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
        {:error, "Invalid value provided for discord_struct: #{inspect(invalid)}"}
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

  defp transform_user(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:discord_username, discord_data.username)
    |> Ash.Changeset.force_change_attribute(:discord_avatar, discord_data.avatar)
    |> Transformations.set_discord_email(discord_data.id)
  end

  defp transform_guild(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> maybe_set_attribute(:description, discord_data.description)
    |> maybe_set_attribute(:icon, discord_data.icon)
  end

  defp transform_guild_member(changeset, discord_data) do
    guild_id = Ash.Changeset.get_argument(changeset, :guild_id)

    changeset
    |> Ash.Changeset.force_change_attribute(:guild_id, guild_id)
    |> Ash.Changeset.force_change_attribute(:user_id, discord_data.user_id)
    |> maybe_set_attribute(:nick, discord_data.nick)
    |> maybe_set_attribute(:roles, discord_data.roles || [])
    |> maybe_set_attribute(:avatar, discord_data.avatar)
    |> Transformations.set_datetime_field(:joined_at, discord_data.joined_at)
    |> Transformations.set_datetime_field(:premium_since, discord_data.premium_since)
    |> Transformations.set_datetime_field(
      :communication_disabled_until,
      discord_data.communication_disabled_until
    )
    |> maybe_set_member_boolean_attributes(discord_data)
  end

  defp maybe_set_member_boolean_attributes(changeset, discord_data) do
    changeset
    |> maybe_set_attribute(:deaf, discord_data.deaf)
    |> maybe_set_attribute(:mute, discord_data.mute)
    |> maybe_set_attribute(:pending, discord_data.pending)
  end

  defp transform_role(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:color, discord_data.color)
    |> Ash.Changeset.force_change_attribute(:permissions, to_string(discord_data.permissions))
    |> maybe_set_role_attributes(discord_data)
  end

  defp maybe_set_role_attributes(changeset, discord_data) do
    changeset
    |> maybe_set_attribute(:hoist, discord_data.hoist)
    |> maybe_set_attribute(:position, discord_data.position)
    |> maybe_set_attribute(:managed, discord_data.managed)
    |> maybe_set_attribute(:mentionable, discord_data.mentionable)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    Ash.Changeset.force_change_attribute(changeset, field, value)
  end

  defp maybe_set_from_argument(changeset, field) do
    case Ash.Changeset.get_argument(changeset, field) do
      nil -> changeset
      value -> Ash.Changeset.force_change_attribute(changeset, field, value)
    end
  end

  defp transform_channel(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> maybe_set_attribute(:position, discord_data.position)
    |> maybe_set_attribute(:topic, discord_data.topic)
    |> maybe_set_attribute(:nsfw, discord_data.nsfw)
    |> maybe_set_attribute(:parent_id, discord_data.parent_id)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> maybe_set_attribute(
      :permission_overwrites,
      Transformations.transform_permission_overwrites(discord_data.permission_overwrites)
    )
  end

  defp transform_message(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:content, discord_data.content || "")
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> Ash.Changeset.force_change_attribute(:author_id, discord_data.author.id)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> maybe_set_attribute(:tts, discord_data.tts)
    |> maybe_set_attribute(:mention_everyone, discord_data.mention_everyone)
    |> maybe_set_attribute(:pinned, discord_data.pinned)
    |> Transformations.set_datetime_field(:timestamp, discord_data.timestamp)
    |> Transformations.set_datetime_field(:edited_timestamp, discord_data.edited_timestamp)
  end

  defp transform_emoji(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:animated, discord_data.animated || false)
    |> maybe_set_attribute(:managed, discord_data.managed)
    |> maybe_set_attribute(:require_colons, discord_data.require_colons)
  end

  defp transform_voice_state(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:user_id, discord_data.user_id)
    |> maybe_set_attribute(:channel_id, discord_data.channel_id)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> Ash.Changeset.force_change_attribute(:session_id, discord_data.session_id)
    |> maybe_set_attribute(:deaf, discord_data.deaf)
    |> maybe_set_attribute(:mute, discord_data.mute)
    |> maybe_set_attribute(:self_deaf, discord_data.self_deaf)
    |> maybe_set_attribute(:self_mute, discord_data.self_mute)
    |> maybe_set_attribute(:self_stream, discord_data.self_stream)
    |> maybe_set_attribute(:self_video, discord_data.self_video)
    |> maybe_set_attribute(:suppress, discord_data.suppress)
    |> Transformations.set_datetime_field(
      :request_to_speak_timestamp,
      discord_data.request_to_speak_timestamp
    )
  end

  defp transform_webhook(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> maybe_set_attribute(:avatar, discord_data.avatar)
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> maybe_set_attribute(:token, discord_data.token)
  end

  defp transform_invite(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:code, discord_data.code)
    |> maybe_set_attribute(:guild_id, get_nested_id(discord_data.guild))
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel.id)
    |> maybe_set_attribute(:inviter_id, get_nested_id(discord_data.inviter))
    |> maybe_set_attribute(:target_user_id, get_nested_id(discord_data.target_user))
    |> maybe_set_attribute(:target_user_type, discord_data.target_user_type)
    |> maybe_set_attribute(:approximate_presence_count, discord_data.approximate_presence_count)
    |> maybe_set_attribute(:approximate_member_count, discord_data.approximate_member_count)
    |> maybe_set_attribute(:uses, discord_data.uses)
    |> maybe_set_attribute(:max_uses, discord_data.max_uses)
    |> maybe_set_attribute(:max_age, discord_data.max_age)
    |> maybe_set_attribute(:temporary, discord_data.temporary)
    |> Transformations.set_datetime_field(:created_at, discord_data.created_at)
  end

  defp transform_message_attachment(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:filename, discord_data.filename)
    |> Ash.Changeset.force_change_attribute(:size, discord_data.size)
    |> Ash.Changeset.force_change_attribute(:url, discord_data.url)
    |> maybe_set_attribute(:proxy_url, discord_data.proxy_url)
    |> maybe_set_attribute(:height, discord_data.height)
    |> maybe_set_attribute(:width, discord_data.width)
  end

  defp transform_message_reaction(changeset, discord_data) do
    changeset
    |> maybe_set_attribute(:emoji_id, get_nested_id(discord_data.emoji))
    |> maybe_set_attribute(:emoji_name, discord_data.emoji && discord_data.emoji.name)
    |> maybe_set_attribute(:emoji_animated, discord_data.emoji && discord_data.emoji.animated)
    |> Ash.Changeset.force_change_attribute(:count, discord_data.count || 1)
    |> maybe_set_attribute(:me, discord_data.me || false)
    # Context fields come from arguments, not from discord_data
    |> maybe_set_from_argument(:user_id)
    |> maybe_set_from_argument(:message_id)
    |> maybe_set_from_argument(:channel_id)
    |> maybe_set_from_argument(:guild_id)
  end

  defp transform_typing_indicator(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:user_id, discord_data.user_id)
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> Transformations.set_datetime_field(:timestamp, discord_data.timestamp)
  end

  defp transform_sticker(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> maybe_set_attribute(:description, discord_data.description)
    |> maybe_set_attribute(:tags, discord_data.tags)
    |> maybe_set_attribute(:type, discord_data.type)
    |> maybe_set_attribute(:format_type, discord_data.format_type)
    |> maybe_set_attribute(:available, discord_data.available)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
  end

  defp transform_interaction(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> maybe_set_attribute(:application_id, discord_data.application_id)
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> maybe_set_attribute(:guild_id, discord_data.guild_id)
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> Ash.Changeset.force_change_attribute(:user_id, get_interaction_user_id(discord_data))
    |> Ash.Changeset.force_change_attribute(:token, discord_data.token)
    |> maybe_set_attribute(:data, discord_data.data)
    |> maybe_set_attribute(:locale, discord_data.locale)
    |> maybe_set_attribute(:app_permissions, Map.get(discord_data, :app_permissions))
    |> maybe_set_attribute(:version, Map.get(discord_data, :version))
    |> maybe_set_attribute(:guild_locale, Map.get(discord_data, :guild_locale))
  end

  # Helper function to safely extract ID from nested structs
  defp get_nested_id(nil), do: nil
  defp get_nested_id(%{id: id}), do: id
  defp get_nested_id(_), do: nil

  # Helper function to extract user ID from interaction (guild vs DM)
  defp get_interaction_user_id(%{user: %{id: id}}), do: id
  defp get_interaction_user_id(%{member: %{user: %{id: id}}}), do: id
  defp get_interaction_user_id(_), do: nil
end
