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
    # Check for discord_struct first
    case Ash.Changeset.get_argument(changeset, :discord_struct) do
      nil ->
        # For backward compatibility with interaction type, check :interaction argument
        cond do
          type == :interaction ->
            case Ash.Changeset.get_argument(changeset, :interaction) do
              nil ->
                # Fallback to API fetch
                AshDiscord.Changes.FromDiscord.ApiFetchers.fetch_from_api(changeset, type)

              interaction when is_map(interaction) ->
                {:ok, interaction}

              invalid ->
                {:error, "Invalid value provided for interaction: #{inspect(invalid)}"}
            end

          # For event-based entities, construct data from arguments
          type in [:typing_indicator, :message_reaction] ->
            construct_event_data(changeset, type)

          true ->
            # Fallback to API fetch for other types
            AshDiscord.Changes.FromDiscord.ApiFetchers.fetch_from_api(changeset, type)
        end

      discord_struct when is_map(discord_struct) ->
        {:ok, discord_struct}

      invalid ->
        {:error, "Invalid value provided for discord_struct: #{inspect(invalid)}"}
    end
  end

  # Construct event data from changeset arguments for event-based entities
  defp construct_event_data(changeset, :typing_indicator) do
    user_id = Ash.Changeset.get_argument_or_attribute(changeset, :user_discord_id)
    channel_id = Ash.Changeset.get_argument_or_attribute(changeset, :channel_discord_id)
    guild_id = Ash.Changeset.get_argument_or_attribute(changeset, :guild_discord_id)

    if user_id && channel_id do
      typing_data = %{
        user_id: user_id,
        channel_id: channel_id,
        guild_id: guild_id,
        timestamp: DateTime.utc_now(),
        member: nil
      }

      {:ok, typing_data}
    else
      {:error, "TypingIndicator requires user_discord_id and channel_discord_id"}
    end
  end

  defp construct_event_data(changeset, :message_reaction) do
    user_id = Ash.Changeset.get_argument_or_attribute(changeset, :user_id)
    message_id = Ash.Changeset.get_argument_or_attribute(changeset, :message_id)
    channel_id = Ash.Changeset.get_argument_or_attribute(changeset, :channel_id)
    guild_id = Ash.Changeset.get_argument_or_attribute(changeset, :guild_id)

    if user_id && message_id && channel_id do
      reaction_data = %{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: guild_id,
        # Will be set from arguments in transformation
        emoji: nil,
        count: 1,
        me: false
      }

      {:ok, reaction_data}
    else
      {:error, "MessageReaction requires user_id, message_id, and channel_id"}
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
    |> maybe_set_attribute(:description, Map.get(discord_data, :description))
    |> maybe_set_attribute(:icon, Map.get(discord_data, :icon))
    |> maybe_set_attribute(:owner_id, Map.get(discord_data, :owner_id))
    |> maybe_set_attribute(:member_count, Map.get(discord_data, :member_count))
  end

  defp transform_guild_member(changeset, discord_data) do
    # Extract the user's Discord ID from the member struct
    user_discord_id = extract_member_user_id(discord_data)

    # Get the guild_discord_id from arguments
    guild_discord_id = Ash.Changeset.get_argument(changeset, :guild_discord_id)

    changeset
    # Set user_discord_id from the member's user data
    |> Ash.Changeset.force_change_attribute(:user_discord_id, user_discord_id)
    |> maybe_set_attribute(:nick, discord_data.nick)
    |> maybe_set_attribute(:avatar, discord_data.avatar)
    |> maybe_set_attribute(:flags, discord_data.flags)
    |> Transformations.set_datetime_field(:joined_at, discord_data.joined_at)
    |> Transformations.set_datetime_field(:premium_since, discord_data.premium_since)
    |> Transformations.set_datetime_field(
      :communication_disabled_until,
      discord_data.communication_disabled_until
    )
    |> maybe_set_member_boolean_attributes(discord_data)
    |> Transformations.manage_guild_relationship(guild_discord_id)
    |> maybe_manage_user_relationship(user_discord_id)
  end

  # Extract user ID from member struct - handles both nested user and direct user_id
  defp extract_member_user_id(%{user: %{id: user_id}}), do: user_id
  defp extract_member_user_id(%{user_id: user_id}), do: user_id
  defp extract_member_user_id(_), do: nil

  # Manage user relationship with auto-creation for guild members
  defp maybe_manage_user_relationship(changeset, nil), do: changeset

  defp maybe_manage_user_relationship(changeset, user_discord_id) do
    Transformations.manage_user_relationship(changeset, user_discord_id)
  end

  defp maybe_set_member_boolean_attributes(changeset, discord_data) do
    changeset
    |> maybe_set_attribute(:deaf, discord_data.deaf)
    |> maybe_set_attribute(:mute, discord_data.mute)
    |> maybe_set_attribute(:pending, discord_data.pending)
  end

  defp transform_role(changeset, discord_data) do
    guild_discord_id = Ash.Changeset.get_argument_or_attribute(changeset, :guild_discord_id)

    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:color, discord_data.color)
    |> Ash.Changeset.force_change_attribute(:permissions, to_string(discord_data.permissions))
    |> maybe_set_role_attributes(discord_data)
    |> Transformations.manage_guild_relationship(guild_discord_id)
  end

  defp maybe_set_role_attributes(changeset, discord_data) do
    changeset
    |> maybe_set_attribute(:hoist, discord_data.hoist)
    |> maybe_set_attribute(:icon, Map.get(discord_data, :icon))
    |> maybe_set_attribute(:unicode_emoji, Map.get(discord_data, :unicode_emoji))
    |> maybe_set_attribute(:position, discord_data.position)
    |> maybe_set_attribute(:managed, discord_data.managed)
    |> maybe_set_attribute(:mentionable, discord_data.mentionable)
    |> maybe_set_attribute(:tags, Map.get(discord_data, :tags))
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_set_from_argument(changeset, field) do
    case Ash.Changeset.get_argument(changeset, field) do
      nil -> changeset
      value -> Ash.Changeset.force_change_attribute(changeset, field, value)
    end
  end

  # Helper to conditionally manage relationships if they exist on the resource
  defp maybe_manage_relationship(changeset, relationship_name, value, manager_fn)
       when not is_nil(value) do
    resource = changeset.resource

    if Ash.Resource.Info.relationship(resource, relationship_name) do
      manager_fn.(changeset, value)
    else
      # If no relationship exists, try setting as attribute if it exists
      maybe_set_attribute(changeset, :"#{relationship_name}_id", value)
    end
  end

  defp maybe_manage_relationship(changeset, _relationship_name, nil, _manager_fn), do: changeset

  defp transform_channel(changeset, discord_data) do
    guild_id = Map.get(discord_data, :guild_id)

    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> maybe_set_attribute(:position, discord_data.position)
    |> maybe_set_attribute(:topic, discord_data.topic)
    |> maybe_set_attribute(:nsfw, discord_data.nsfw)
    |> maybe_set_attribute(:parent_id, discord_data.parent_id)
    |> maybe_set_attribute(
      :permission_overwrites,
      Transformations.transform_permission_overwrites(discord_data.permission_overwrites)
    )
    |> maybe_manage_relationship(:guild, guild_id, fn cs, id ->
      Transformations.manage_guild_relationship(cs, id)
    end)
  end

  defp transform_message(changeset, discord_data) do
    # Get guild_discord_id from arguments or struct
    guild_discord_id =
      case discord_data do
        %{guild_id: guild_id} when not is_nil(guild_id) -> guild_id
        _ -> Ash.Changeset.get_argument(changeset, :guild_discord_id)
      end

    # Get channel_discord_id from arguments or struct
    channel_discord_id =
      case discord_data do
        %{channel_id: channel_id} when not is_nil(channel_id) -> channel_id
        _ -> Ash.Changeset.get_argument(changeset, :channel_discord_id)
      end

    # Extract author ID from the message struct
    author_discord_id =
      case discord_data do
        %{author: %{id: author_id}} when not is_nil(author_id) -> author_id
        _ -> nil
      end

    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:content, discord_data.content || "")
    |> maybe_set_attribute(:embeds, discord_data.embeds || [])
    # Manage relationships
    |> maybe_manage_guild_relationship(guild_discord_id)
    |> maybe_manage_channel_relationship(channel_discord_id)
    |> maybe_manage_author_relationship(author_discord_id)
  end

  # Manage guild relationship for messages
  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    Transformations.manage_guild_relationship(changeset, guild_discord_id)
  end

  # Manage channel relationship for messages
  defp maybe_manage_channel_relationship(changeset, nil), do: changeset

  defp maybe_manage_channel_relationship(changeset, channel_discord_id) do
    Ash.Changeset.manage_relationship(changeset, :channel, channel_discord_id,
      type: :append_and_remove,
      on_no_match: {:create, :from_discord},
      use_identities: [:discord_id],
      value_is_key: :discord_id
    )
  end

  # Manage author relationship for messages
  defp maybe_manage_author_relationship(changeset, nil), do: changeset

  defp maybe_manage_author_relationship(changeset, author_discord_id) do
    Transformations.manage_user_relationship(changeset, author_discord_id, :author)
  end

  defp transform_emoji(changeset, discord_data) do
    # Determine if this is a custom emoji (has an ID)
    custom =
      case discord_data.id do
        nil -> false
        _ -> true
      end

    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:animated, discord_data.animated || false)
    |> Ash.Changeset.force_change_attribute(:custom, custom)
    |> maybe_set_attribute(:available, Map.get(discord_data, :available, true))
    |> maybe_set_attribute(:require_colons, Map.get(discord_data, :require_colons, true))
    |> maybe_set_attribute(:managed, discord_data.managed || false)
    |> maybe_set_attribute(:roles, Map.get(discord_data, :roles, []))
    |> maybe_manage_emoji_user_relationship(discord_data)
  end

  # Manage user relationship for emojis
  defp maybe_manage_emoji_user_relationship(changeset, %{user: %{id: user_id}})
       when not is_nil(user_id) do
    Transformations.manage_user_relationship(changeset, user_id)
  end

  defp maybe_manage_emoji_user_relationship(changeset, _), do: changeset

  defp transform_voice_state(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:user_discord_id, discord_data.user_id)
    |> maybe_set_attribute(:channel_discord_id, discord_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, discord_data.guild_id)
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
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> maybe_set_attribute(:avatar, Map.get(discord_data, :avatar))
    |> maybe_set_attribute(:channel_discord_id, Map.get(discord_data, :channel_id))
    |> maybe_set_attribute(:guild_discord_id, Map.get(discord_data, :guild_id))
    |> maybe_set_attribute(:token, Map.get(discord_data, :token))
  end

  defp transform_invite(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:code, discord_data.code)
    |> maybe_set_attribute(:guild_discord_id, get_nested_id(discord_data.guild))
    |> Ash.Changeset.force_change_attribute(:channel_discord_id, discord_data.channel.id)
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
    |> Ash.Changeset.force_change_attribute(:user_discord_id, discord_data.user_id)
    |> Ash.Changeset.force_change_attribute(:channel_discord_id, discord_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, discord_data.guild_id)
    |> set_typing_timestamp(discord_data)
    |> maybe_set_attribute(:member, Map.get(discord_data, :member))
  end

  # Handle timestamp setting for typing indicators (matches original logic)
  defp set_typing_timestamp(changeset, %{timestamp: timestamp}) when not is_nil(timestamp) do
    # Parse Unix timestamp if it's an integer
    parsed_timestamp =
      case timestamp do
        timestamp when is_integer(timestamp) ->
          case DateTime.from_unix(timestamp) do
            {:ok, dt} -> dt
            _ -> nil
          end

        timestamp when is_binary(timestamp) ->
          case DateTime.from_iso8601(timestamp) do
            {:ok, dt, _} -> dt
            _ -> nil
          end

        %DateTime{} = dt ->
          dt

        _ ->
          nil
      end

    Ash.Changeset.force_change_attribute(changeset, :timestamp, parsed_timestamp)
  end

  defp set_typing_timestamp(changeset, _) do
    # Default to current timestamp if none provided
    Ash.Changeset.force_change_attribute(changeset, :timestamp, DateTime.utc_now())
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
    |> maybe_set_attribute(:guild_discord_id, discord_data.guild_id)
  end

  defp transform_interaction(changeset, discord_data) do
    # Extract custom_id from interaction data
    custom_id =
      case discord_data do
        %{data: %{custom_id: custom_id}} -> custom_id
        _ -> nil
      end

    # Extract user ID from interaction (handles both guild and DM interactions)
    user_discord_id = get_interaction_user_id(discord_data)

    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> Ash.Changeset.force_change_attribute(:token, discord_data.token)
    |> Ash.Changeset.force_change_attribute(:application_id, discord_data.application_id)
    |> maybe_set_attribute(:custom_id, custom_id)
    # Store full interaction struct as data
    |> maybe_set_attribute(:data, discord_data)
    |> maybe_manage_interaction_guild_relationship(discord_data)
    |> maybe_manage_interaction_channel_relationship(discord_data)
    |> maybe_manage_interaction_user_relationship(user_discord_id)
  end

  # Manage guild relationship for interactions
  defp maybe_manage_interaction_guild_relationship(changeset, %{guild_id: guild_id})
       when not is_nil(guild_id) do
    Transformations.manage_guild_relationship(changeset, guild_id)
  end

  defp maybe_manage_interaction_guild_relationship(changeset, _), do: changeset

  # Manage channel relationship for interactions
  defp maybe_manage_interaction_channel_relationship(changeset, %{
         channel_id: channel_id,
         guild_id: guild_id
       })
       when not is_nil(channel_id) do
    Ash.Changeset.manage_relationship(
      changeset,
      :channel,
      %{discord_id: channel_id, guild_discord_id: guild_id},
      type: :append_and_remove,
      on_no_match: {:create, :from_discord}
    )
  end

  defp maybe_manage_interaction_channel_relationship(changeset, _), do: changeset

  # Manage user relationship for interactions
  defp maybe_manage_interaction_user_relationship(changeset, nil), do: changeset

  defp maybe_manage_interaction_user_relationship(changeset, user_discord_id) do
    Transformations.manage_user_relationship(changeset, user_discord_id)
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
