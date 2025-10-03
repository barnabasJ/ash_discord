defmodule AshDiscord.Consumer do
  @moduledoc """
  Enhanced Nostrum consumer that integrates AshDiscord command handling with advanced configuration capabilities.

  This module provides a `using` macro that allows you to create Discord consumers
  with built-in AshDiscord command handling capabilities, selective callback processing,
  and environment-specific optimizations.

  ## Basic Usage

      defmodule MyApp.DiscordConsumer do
        use AshDiscord.Consumer

        # Optionally override callbacks to extend behavior
        def handle_message_create(message) do
          # Custom message processing logic
          Logger.info("Custom message processing")
          :ok
        end

        def handle_ready(data) do
          # Custom ready event handling
          Logger.info("Bot ready with custom logic!")
          :ok
        end
      end

  ## Advanced Configuration

  AshDiscord.Consumer supports advanced configuration for performance optimization,
  selective callback processing, and environment-specific profiles:

      defmodule MyApp.ProductionConsumer do
        use AshDiscord.Consumer

        ash_discord_consumer do
          domains [MyApp.Chat, MyApp.Discord]
          store_bot_messages false
        end
      end

  ## Callback Categories

  For easier configuration, callbacks are organized into categories:

  - **`:message_events`**: message_create, message_update, message_delete, message_delete_bulk
  - **`:reaction_events`**: message_reaction_add, message_reaction_remove, message_reaction_remove_all
  - **`:guild_events`**: guild_create, guild_update, guild_delete
  - **`:role_events`**: guild_role_create, guild_role_update, guild_role_delete
  - **`:member_events`**: guild_member_add, guild_member_update, guild_member_remove
  - **`:channel_events`**: channel_create, channel_update, channel_delete
  - **`:interaction_events`**: interaction_create, application_command
  - **`:voice_events`**: voice_state_update
  - **`:typing_events`**: typing_start
  - **`:invite_events`**: invite_create, invite_delete
  - **`:unknown_events`**: unknown_event


  ## Built-in Features

  When you `use AshDiscord.Consumer`, you automatically get:

  - Automatic Discord command registration on bot ready
  - INTERACTION_CREATE event handling with routing to Ash actions  
  - Selective callback processing for performance optimization
  - Environment-aware configuration defaults
  - Backward compatibility with existing message handling patterns

  ## Configuration Examples

      # Minimal bot for slash commands only
      defmodule MyApp.MinimalConsumer do
        use AshDiscord.Consumer

        ash_discord_consumer do
          domains [MyApp.Discord]
        end
      end
  """

  @doc """
  Callback for handling MESSAGE_CREATE events from Discord.

  Called whenever a message is created in a channel the bot can see.
  The default implementation stores the message in the Discord domain
  and processes it if the bot is mentioned or it's a direct message.

  ## Parameters

  - `message` - The Discord message struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_create(
              message :: Nostrum.Struct.Message.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_CREATE events from Discord.

  Called when the bot joins a new guild or when guilds are loaded on startup.

  ## Parameters

  - `guild` - The Discord guild struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_create(
              guild :: Nostrum.Struct.Guild.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_UPDATE events from Discord.

  Called when a guild's settings are updated (name, icon, description, etc.).

  ## Parameters

  - `guild` - The updated Discord guild struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_update(
              {old_guild :: Nostrum.Struct.Guild.t(), new_guild :: Nostrum.Struct.Guild.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_DELETE events from Discord.

  Called when a guild becomes unavailable or when the bot is removed from a guild.

  ## Parameters

  - `data` - Guild delete data containing guild ID and unavailable flag
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_delete(
              {old_guild :: Nostrum.Struct.Guild.t(), unavailable :: boolean},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling READY events from Discord.

  Called when the bot successfully connects to Discord and is ready to receive events.
  The default implementation registers Discord commands with the API.

  ## Parameters

  - `data` - The ready event data from Discord
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_ready(
              data :: Nostrum.Struct.Event.Ready.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling INTERACTION_CREATE events from Discord.

  Called for all interaction events (slash commands, buttons, select menus, etc.).
  The default implementation routes application commands to AshDiscord handlers.

  ## Parameters

  - `interaction` - The Discord interaction struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_interaction_create(
              interaction :: Nostrum.Struct.Interaction.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling application command interactions specifically.

  Called for slash command interactions after `handle_interaction_create/2`.
  The default implementation routes the command to the appropriate Ash action.

  ## Parameters

  - `interaction` - The Discord application command interaction struct
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_application_command(
              interaction :: Nostrum.Struct.Interaction.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_CREATE events from Discord.

  Called when a new role is created in a guild the bot has access to.

  ## Parameters

  - `data` - Tuple of {guild_id, new_role}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_create(
              {guild_id :: integer, new_role :: Nostrum.Struct.Guild.Role.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_UPDATE events from Discord.

  Called when a role is updated in a guild the bot has access to.

  ## Parameters

  - `data` - Tuple of {guild_id, old_role | nil, new_role}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_update(
              {guild_id :: integer, old_role :: Nostrum.Struct.Guild.Role.t() | nil,
               new_role :: Nostrum.Struct.Guild.Role.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_DELETE events from Discord.

  Called when a role is deleted in a guild the bot has access to.

  ## Parameters

  - `data` - Tuple of {guild_id, old_role}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_delete(
              {guild_id :: integer, old_role :: Nostrum.Struct.Guild.Role.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_ADD events from Discord.

  Called when a new member joins a guild the bot has access to.

  ## Parameters

  - `data` - Tuple of {guild_id, new_member}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_add(
              {guild_id :: integer, new_member :: Nostrum.Struct.Guild.Member.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_UPDATE events from Discord.

  Called when a guild member is updated (roles, nickname, etc.).

  ## Parameters

  - `data` - Tuple of {guild_id, old_member | nil, new_member}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_update(
              {guild_id :: integer, old_member :: Nostrum.Struct.Guild.Member.t() | nil,
               new_member :: Nostrum.Struct.Guild.Member.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_REMOVE events from Discord.

  Called when a member leaves a guild the bot has access to.

  ## Parameters

  - `data` - Tuple of {guild_id, old_member}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_remove(
              {guild_id :: integer, old_member :: Nostrum.Struct.Guild.Member.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_CREATE events from Discord.

  Called when a channel is created in a guild the bot can see.

  ## Parameters

  - `channel` - The Discord channel struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_create(
              channel :: Nostrum.Struct.Channel.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_UPDATE events from Discord.

  Called when a channel is updated in a guild the bot can see.

  ## Parameters

  - `data` - Tuple of {old_channel | nil, new_channel}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_update(
              {old_channel :: Nostrum.Struct.Channel.t() | nil,
               new_channel :: Nostrum.Struct.Channel.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_DELETE events from Discord.

  Called when a channel is deleted in a guild the bot can see.

  ## Parameters

  - `channel` - The Discord channel struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_delete(
              channel :: Nostrum.Struct.Channel.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_UPDATE events from Discord.

  Called when a message is updated/edited in a channel the bot can see.

  ## Parameters

  - `data` - Tuple of {old_message | nil, updated_message}
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_update(
              {old_message :: Nostrum.Struct.Message.t() | nil,
               updated_message :: Nostrum.Struct.Message.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_DELETE events from Discord.

  Called when a message is deleted in a channel the bot can see.

  ## Parameters

  - `data` - The message delete data (contains message_id, channel_id, guild_id)
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_delete(
              data :: Nostrum.Struct.Event.MessageDelete.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_DELETE_BULK events from Discord.

  Called when multiple messages are deleted at once in a channel.

  ## Parameters

  - `data` - The bulk delete data (contains ids list, channel_id, guild_id)
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_delete_bulk(
              data :: Nostrum.Struct.Event.MessageDeleteBulk.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_ADD events from Discord.

  Called when a reaction is added to a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction add data (contains user_id, message_id, channel_id, guild_id, emoji)
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_add(
              data :: Nostrum.Struct.Event.MessageReactionAdd.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_REMOVE events from Discord.

  Called when a reaction is removed from a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction remove data (contains user_id, message_id, channel_id, guild_id, emoji)
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_remove(
              data :: Nostrum.Struct.Event.MessageReactionRemove.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_REMOVE_ALL events from Discord.

  Called when all reactions are removed from a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction remove all data (contains message_id, channel_id, guild_id)
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_remove_all(
              data :: Nostrum.Struct.Event.MessageReactionRemoveAll.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling VOICE_STATE_UPDATE events from Discord.

  Called when a user's voice state changes (joins/leaves voice channel, mutes, etc.).

  ## Parameters

  - `voice_state` - The Discord voice state struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_voice_state_update(
              voice_state :: Nostrum.Struct.Event.VoiceState.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling TYPING_START events from Discord.

  Called when a user starts typing in a channel.

  ## Parameters

  - `typing_data` - The Discord typing event data from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_typing_start(
              typing_data :: Nostrum.Struct.Event.TypingStart.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling INVITE_CREATE events from Discord.

  Called when an invite is created in a guild the bot can see.

  ## Parameters

  - `invite` - The Discord invite struct from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_invite_create(
              invite :: Nostrum.Struct.Event.InviteCreate.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling INVITE_DELETE events from Discord.

  Called when an invite is deleted in a guild the bot can see.

  ## Parameters

  - `invite_data` - The Discord invite deletion data from Nostrum
  - `ws_state` - The WebSocket state from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_invite_delete(
              invite_data :: Nostrum.Struct.Event.InviteDelete.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @doc """
  Callback for handling unknown or unhandled Discord events.

  Called for any Discord event that doesn't have a specific handler.
  The default implementation logs the event and ignores it.

  ## Parameters

  - `event` - The complete Discord event tuple `{event_type, data, ws_state}`

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_unknown_event(event :: tuple()) :: :ok | {:error, any()}

  @doc """
  Callback for creating users from Discord interaction data.

  This callback allows consumers to specify how Discord users should be created
  or resolved when processing interactions. The default implementation returns nil.

  ## Parameters

  - `discord_user` - The Discord user struct from the interaction

  ## Returns

  Should return a user struct, `{:ok, user}`, `{:error, reason}`, or `nil`.
  """
  @callback create_user_from_discord(discord_user :: map()) ::
              any() | {:ok, any()} | {:error, any()} | nil

  @callback handle_presence_update(
              {guild_id :: integer, old_presence :: map | nil, new_presence :: map},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @callback handle_user_update(
              {old_user :: Nostrum.Struct.User.t() | nil, new_user :: Nostrum.Struct.User.t()},
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @callback handle_guild_unavailable(
              guild :: Nostrum.Struct.Guild.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  @callback handle_guild_available(
              guild :: Nostrum.Struct.Guild.t(),
              ws_state :: Nostrum.Struct.WSState.t()
            ) :: :ok | {:error, any()}

  # Make all callbacks optional with default implementations
  @optional_callbacks [
    create_user_from_discord: 1,
    handle_application_command: 2,
    handle_channel_create: 2,
    handle_channel_delete: 2,
    handle_channel_update: 2,
    handle_guild_create: 2,
    handle_guild_delete: 2,
    handle_guild_member_add: 2,
    handle_guild_member_remove: 2,
    handle_guild_member_update: 2,
    handle_guild_role_create: 2,
    handle_guild_role_delete: 2,
    handle_guild_role_update: 2,
    handle_guild_update: 2,
    handle_guild_unavailable: 2,
    handle_guild_available: 2,
    handle_interaction_create: 2,
    handle_invite_create: 2,
    handle_invite_delete: 2,
    handle_message_create: 2,
    handle_message_delete: 2,
    handle_message_delete_bulk: 2,
    handle_message_reaction_add: 2,
    handle_message_reaction_remove: 2,
    handle_message_reaction_remove_all: 2,
    handle_message_update: 2,
    handle_presence_update: 2,
    handle_ready: 2,
    handle_typing_start: 2,
    handle_unknown_event: 1,
    handle_user_update: 2,
    handle_voice_state_update: 2
  ]

  def collect_commands(domains) do
    Enum.flat_map(domains, fn domain ->
      AshDiscord.Info.discord_commands(domain)
    end)
  end

  def to_discord_command(command) do
    %{
      name: Atom.to_string(command.name),
      description: command.description,
      type: discord_command_type(command.type),
      options: Enum.sort_by(Enum.map(command.options, &to_discord_option/1), & &1.required, :desc)
    }
  end

  def to_discord_option(option) do
    base_option = %{
      name: Atom.to_string(option.name),
      description: option.description,
      type: discord_option_type(option.type),
      required: option.required
    }

    if option.choices do
      Map.put(base_option, :choices, option.choices)
    else
      base_option
    end
  end

  defp discord_command_type(:chat_input), do: 1
  defp discord_command_type(:user), do: 2
  defp discord_command_type(:message), do: 3

  defp discord_option_type(:string), do: 3
  defp discord_option_type(:integer), do: 4
  defp discord_option_type(:boolean), do: 5
  defp discord_option_type(:user), do: 6
  defp discord_option_type(:channel), do: 7
  defp discord_option_type(:role), do: 8
  defp discord_option_type(:mentionable), do: 9
  defp discord_option_type(:number), do: 10
  defp discord_option_type(:attachment), do: 11

  # Consumer module that provides behavior and default implementations
  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour AshDiscord.Consumer

      # Include DSL functionality
      use AshDiscord.Consumer.Dsl, unquote(opts)

      use Nostrum.Consumer
      require Logger
      require Ash.Query
      alias AshDiscord.Logger, as: AshLogger

      # TODO: this shouldn't be in this module
      defp parse_timestamp(timestamp_string) do
        case DateTime.from_iso8601(timestamp_string) do
          {:ok, datetime, _offset} -> datetime
          {:ok, datetime} -> datetime
          {:error, _} -> nil
        end
      end

      def handle_event(event) do
        AshDiscord.Consumer.Handler.handle_event(__MODULE__, event)
      end
    end
  end
end
