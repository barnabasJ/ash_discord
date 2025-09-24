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
          debug_logging false
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
  - Error handling and logging (configurable verbosity)
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

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_create(message :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_CREATE events from Discord.

  Called when the bot joins a new guild or when guilds are loaded on startup.

  ## Parameters

  - `guild` - The Discord guild struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_create(guild :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_UPDATE events from Discord.

  Called when a guild's settings are updated (name, icon, description, etc.).

  ## Parameters

  - `guild` - The updated Discord guild struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_update(guild :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_DELETE events from Discord.

  Called when a guild becomes unavailable or when the bot is removed from a guild.

  ## Parameters

  - `data` - Guild delete data containing guild ID and unavailable flag

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_delete(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling READY events from Discord.

  Called when the bot successfully connects to Discord and is ready to receive events.
  The default implementation registers Discord commands with the API.

  ## Parameters

  - `data` - The ready event data from Discord

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_ready(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling INTERACTION_CREATE events from Discord.

  Called for all interaction events (slash commands, buttons, select menus, etc.).
  The default implementation routes application commands to AshDiscord handlers.

  ## Parameters

  - `interaction` - The Discord interaction struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_interaction_create(interaction :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling application command interactions specifically.

  Called for slash command interactions after `handle_interaction_create/1`.
  The default implementation routes the command to the appropriate Ash action.

  ## Parameters

  - `interaction` - The Discord application command interaction struct

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_application_command(interaction :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_CREATE events from Discord.

  Called when a new role is created in a guild the bot has access to.

  ## Parameters

  - `role` - The Discord role struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_create(role :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_UPDATE events from Discord.

  Called when a role is updated in a guild the bot has access to.

  ## Parameters

  - `role` - The updated Discord role struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_update(role :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_ROLE_DELETE events from Discord.

  Called when a role is deleted in a guild the bot has access to.

  ## Parameters

  - `data` - The role deletion data (contains role_id and guild_id)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_role_delete(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_ADD events from Discord.

  Called when a new member joins a guild the bot has access to.

  ## Parameters

  - `member` - The Discord guild member struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_add(guild_id :: integer(), member :: map()) ::
              :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_UPDATE events from Discord.

  Called when a guild member is updated (roles, nickname, etc.).

  ## Parameters

  - `member` - The updated Discord guild member struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_update(guild_id :: integer(), member :: map()) ::
              :ok | {:error, any()}

  @doc """
  Callback for handling GUILD_MEMBER_REMOVE events from Discord.

  Called when a member leaves a guild the bot has access to.

  ## Parameters

  - `data` - The member removal data (contains user and guild_id)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_guild_member_remove(guild_id :: integer(), member :: map()) ::
              :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_CREATE events from Discord.

  Called when a channel is created in a guild the bot can see.

  ## Parameters

  - `channel` - The Discord channel struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_create(channel :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_UPDATE events from Discord.

  Called when a channel is updated in a guild the bot can see.

  ## Parameters

  - `channel` - The Discord channel struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_update(channel :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling CHANNEL_DELETE events from Discord.

  Called when a channel is deleted in a guild the bot can see.

  ## Parameters

  - `channel` - The Discord channel struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_channel_delete(channel :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_UPDATE events from Discord.

  Called when a message is updated/edited in a channel the bot can see.

  ## Parameters

  - `message` - The updated Discord message struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_update(message :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_DELETE events from Discord.

  Called when a message is deleted in a channel the bot can see.

  ## Parameters

  - `data` - The message delete data (contains message_id, channel_id, guild_id)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_delete(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_DELETE_BULK events from Discord.

  Called when multiple messages are deleted at once in a channel.

  ## Parameters

  - `data` - The bulk delete data (contains ids list, channel_id, guild_id)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_delete_bulk(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_ADD events from Discord.

  Called when a reaction is added to a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction add data (contains user_id, message_id, channel_id, guild_id, emoji)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_add(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_REMOVE events from Discord.

  Called when a reaction is removed from a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction remove data (contains user_id, message_id, channel_id, guild_id, emoji)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_remove(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling MESSAGE_REACTION_REMOVE_ALL events from Discord.

  Called when all reactions are removed from a message in a channel the bot can see.

  ## Parameters

  - `data` - The reaction remove all data (contains message_id, channel_id, guild_id)

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_message_reaction_remove_all(data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling VOICE_STATE_UPDATE events from Discord.

  Called when a user's voice state changes (joins/leaves voice channel, mutes, etc.).

  ## Parameters

  - `voice_state` - The Discord voice state struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_voice_state_update(voice_state :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling TYPING_START events from Discord.

  Called when a user starts typing in a channel.

  ## Parameters

  - `typing_data` - The Discord typing event data from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_typing_start(typing_data :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling INVITE_CREATE events from Discord.

  Called when an invite is created in a guild the bot can see.

  ## Parameters

  - `invite` - The Discord invite struct from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_invite_create(invite :: map()) :: :ok | {:error, any()}

  @doc """
  Callback for handling INVITE_DELETE events from Discord.

  Called when an invite is deleted in a guild the bot can see.

  ## Parameters

  - `invite_data` - The Discord invite deletion data from Nostrum

  ## Returns

  Should return `:ok` on success or `{:error, reason}` on failure.
  """
  @callback handle_invite_delete(invite_data :: map()) :: :ok | {:error, any()}

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

  # Make all callbacks optional with default implementations
  @optional_callbacks [
    handle_message_create: 1,
    handle_message_update: 1,
    handle_message_delete: 1,
    handle_message_delete_bulk: 1,
    handle_message_reaction_add: 1,
    handle_message_reaction_remove: 1,
    handle_message_reaction_remove_all: 1,
    handle_guild_create: 1,
    handle_guild_update: 1,
    handle_guild_delete: 1,
    handle_ready: 1,
    handle_interaction_create: 1,
    handle_application_command: 1,
    handle_guild_role_create: 1,
    handle_guild_role_update: 1,
    handle_guild_role_delete: 1,
    handle_guild_member_add: 2,
    handle_guild_member_update: 2,
    handle_guild_member_remove: 2,
    handle_channel_create: 1,
    handle_channel_update: 1,
    handle_channel_delete: 1,
    handle_voice_state_update: 1,
    handle_typing_start: 1,
    handle_invite_create: 1,
    handle_invite_delete: 1,
    handle_unknown_event: 1,
    create_user_from_discord: 1
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

      defp parse_timestamp(timestamp_string) do
        case DateTime.from_iso8601(timestamp_string) do
          {:ok, datetime, _offset} -> datetime
          {:ok, datetime} -> datetime
          {:error, _} -> nil
        end
      end

      # Default callback implementations with automatic resource handling
      def handle_message_create(message) do
        with {:ok, message_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(__MODULE__),
             {:ok, store_bot_messages} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_store_bot_messages(__MODULE__) do
          require Logger
          Logger.debug("Message resource found: #{inspect(message_resource)}")

          # Skip bot messages if store_bot_messages is false
          if message.author.bot && !store_bot_messages do
            :ok
          else
            case message_resource
                 |> Ash.Changeset.for_create(:from_discord, %{
                   discord_struct: message,
                   channel_discord_id: message.channel_id,
                   guild_discord_id: message.guild_id
                 })
                 |> Ash.Changeset.set_context(%{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 })
                 |> Ash.create() do
              {:ok, _message_record} ->
                :ok

              {:error, error} ->
                require Logger
                Logger.error("Failed to save message #{message.id}: #{inspect(error)}")
                # Don't crash the consumer
                :ok
            end
          end
        else
          :error ->
            # No message resource configured
            :ok
        end
      end

      def handle_message_update(message) do
        with {:ok, message_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(__MODULE__) do
          # Update the existing message - provide channel and guild IDs from the message struct
          case message_resource
               |> Ash.Changeset.for_create(:from_discord, %{
                 discord_struct: message,
                 channel_discord_id: message.channel_id,
                 guild_discord_id: message.guild_id
               })
               |> Ash.Changeset.set_context(%{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               })
               |> Ash.create() do
            {:ok, _message_record} ->
              :ok

            {:error, error} ->
              require Logger
              Logger.error("Failed to update message #{message.id}: #{inspect(error)}")
              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No message resource configured
            :ok
        end
      end

      def handle_message_delete(data) do
        with {:ok, message_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(__MODULE__) do
          require Ash.Query

          # Delete the message by discord_id
          query =
            message_resource
            |> Ash.Query.filter(discord_id: data.id)

          case Ash.bulk_destroy(query, :destroy, %{},
                 context: %{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 }
               ) do
            %Ash.BulkResult{status: :success} ->
              :ok

            result ->
              require Logger
              Logger.error("Failed to delete message #{data.id}: #{inspect(result)}")
              :ok
          end
        else
          :error ->
            # No message resource configured
            :ok
        end
      end

      def handle_message_delete_bulk(data) do
        with {:ok, message_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(__MODULE__) do
          # Handle empty IDs list gracefully
          if data.ids == [] do
            :ok
          else
            require Ash.Query

            # Delete all messages by discord_id
            # We need to build a filter that checks if discord_id is in the list
            filter = [or: Enum.map(data.ids, fn id -> [discord_id: id] end)]

            query =
              message_resource
              |> Ash.Query.filter(filter)

            case Ash.bulk_destroy(query, :destroy, %{},
                   context: %{
                     private: %{ash_discord?: true},
                     shared: %{private: %{ash_discord?: true}}
                   }
                 ) do
              %Ash.BulkResult{status: :success} ->
                :ok

              result ->
                require Logger
                Logger.error("Failed to bulk delete messages: #{inspect(result)}")
                :ok
            end
          end
        else
          :error ->
            # No message resource configured
            :ok
        end
      end

      def handle_guild_create(guild) do
        with {:ok, domains} <- AshDiscord.Consumer.Info.ash_discord_consumer_domains(__MODULE__) do
          commands = AshDiscord.Consumer.collect_commands(domains)

          # Filter by scope and register appropriately
          global_commands =
            commands
            |> Enum.filter(&(&1.scope == :global))
            |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

          guild_commands =
            commands
            |> Enum.filter(&(&1.scope == :guild))
            |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

          case Nostrum.Api.ApplicationCommand.bulk_overwrite_guild_commands(
                 guild.id,
                 guild_commands
               ) do
            {:ok, _} ->
              require Logger

              Logger.info(
                "Registered #{length(guild_commands)} guild command(s) for #{guild.name}"
              )

            {:error, error} ->
              require Logger

              Logger.error(
                "Failed to register guild commands for #{guild.name}: #{inspect(error)}"
              )
          end
        end

        with {:ok, guild_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(__MODULE__) do
          case guild_resource
               |> Ash.Changeset.for_create(:from_discord, %{
                 discord_id: guild.id,
                 discord_struct: guild
               })
               |> Ash.Changeset.set_context(%{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               })
               |> Ash.create() do
            {:ok, _guild_record} ->
              :ok

            {:error, error} ->
              require Logger
              Logger.error("Failed to save guild #{guild.name} (#{guild.id}): #{inspect(error)}")
              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No guild resource configured
            :ok
        end
      end

      def handle_guild_update(guild) do
        with {:ok, guild_resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(__MODULE__) do
          case guild_resource
               |> Ash.Changeset.for_create(:from_discord, %{
                 discord_id: guild.id,
                 discord_struct: guild
               })
               |> Ash.Changeset.set_context(%{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               })
               |> Ash.create() do
            {:ok, _guild_record} ->
              :ok

            {:error, error} ->
              require Logger

              Logger.error(
                "Failed to update guild #{guild.name} (#{guild.id}): #{inspect(error)}"
              )

              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No guild resource configured
            :ok
        end
      end

      def handle_guild_delete(data), do: :ok

      def handle_ready(data) do
        # Register Discord commands when bot is ready
        with {:ok, domains} <- AshDiscord.Consumer.Info.ash_discord_consumer_domains(__MODULE__) do
          commands = AshDiscord.Consumer.collect_commands(domains)

          # Filter by scope and register appropriately
          global_commands =
            commands
            |> Enum.filter(&(&1.scope == :global))
            |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

          guild_commands =
            commands
            |> Enum.filter(&(&1.scope == :guild))
            |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

          # Register global commands
          if length(global_commands) > 0 do
            case Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands(global_commands) do
              {:ok, _} ->
                require Logger
                Logger.info("Registered #{length(global_commands)} global command(s)")

              {:error, error} ->
                require Logger
                Logger.error("Failed to register global commands: #{inspect(error)}")
            end
          end
        end

        :ok
      end

      def handle_interaction_create(interaction) do
        require Logger
        Logger.debug("Processing Discord interaction: #{interaction.id}")
        # Note: Library users can implement their own interaction processing here
        :ok
      end

      def handle_application_command(interaction) do
        command_name = String.to_existing_atom(interaction.data.name)
        require Logger
        Logger.info("Processing slash command: #{command_name} from user #{interaction.user.id}")

        case find_command(command_name) do
          nil ->
            Logger.error("Unknown command: #{command_name}")
            respond_with_error(interaction, "Unknown command")

          command ->
            # Apply command filtering based on guild context
            if command_allowed_for_interaction?(interaction, command) do
              AshDiscord.InteractionRouter.route_interaction(interaction, command,
                consumer: __MODULE__
              )
            else
              Logger.warning("Command #{command_name} filtered for guild #{interaction.guild_id}")
              respond_with_error(interaction, "This command is not available in this server")
            end
        end
      end

      # Default callback_enabled? implementation
      def callback_enabled?(_callback_name), do: true

      # Main event dispatcher - routes Discord events to appropriate callbacks
      def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
        handle_message_create(message)
      end

      def handle_event({:MESSAGE_UPDATE, {_old_message, message}, _ws_state}) do
        handle_message_update(message)
      end

      def handle_event({:MESSAGE_DELETE, data, _ws_state}) do
        handle_message_delete(data)
      end

      def handle_event({:MESSAGE_DELETE_BULK, data, _ws_state}) do
        handle_message_delete_bulk(data)
      end

      def handle_event({:MESSAGE_REACTION_ADD, data, _ws_state}) do
        handle_message_reaction_add(data)
      end

      def handle_event({:MESSAGE_REACTION_REMOVE, data, _ws_state}) do
        handle_message_reaction_remove(data)
      end

      def handle_event({:MESSAGE_REACTION_REMOVE_ALL, data, _ws_state}) do
        handle_message_reaction_remove_all(data)
      end

      def handle_event({:GUILD_CREATE, guild, _ws_state}) do
        handle_guild_create(guild)
      end

      def handle_event({:GUILD_UPDATE, guild, _ws_state}) do
        handle_guild_update(guild)
      end

      def handle_event({:GUILD_DELETE, data, _ws_state}) do
        handle_guild_delete(data)
      end

      def handle_event({:READY, data, _ws_state}) do
        handle_ready(data)
      end

      def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
        handle_interaction_create(interaction)

        case interaction.type do
          # Application command
          2 ->
            handle_application_command(interaction)

          _ ->
            :ok
        end
      end

      def handle_event({:GUILD_ROLE_CREATE, role, _ws_state}) do
        handle_guild_role_create(role)
      end

      def handle_event({:GUILD_ROLE_UPDATE, role, _ws_state}) do
        handle_guild_role_update(role)
      end

      def handle_event({:GUILD_ROLE_DELETE, data, _ws_state}) do
        handle_guild_role_delete(data)
      end

      def handle_event({:GUILD_MEMBER_ADD, {guild_id, member}, _ws_state}) do
        handle_guild_member_add(guild_id, member)
      end

      def handle_event({:GUILD_MEMBER_UPDATE, {guild_id, member}, _ws_state}) do
        handle_guild_member_update(guild_id, member)
      end

      def handle_event({:GUILD_MEMBER_REMOVE, {guild_id, member}, _ws_state}) do
        handle_guild_member_remove(guild_id, member)
      end

      def handle_event({:CHANNEL_CREATE, channel, _ws_state}) do
        handle_channel_create(channel)
      end

      def handle_event({:CHANNEL_UPDATE, channel, _ws_state}) do
        handle_channel_update(channel)
      end

      def handle_event({:CHANNEL_DELETE, channel, _ws_state}) do
        handle_channel_delete(channel)
      end

      def handle_event({:VOICE_STATE_UPDATE, voice_state, _ws_state}) do
        handle_voice_state_update(voice_state)
      end

      def handle_event({:TYPING_START, typing_data, _ws_state}) do
        handle_typing_start(typing_data)
      end

      def handle_event({:INVITE_CREATE, invite, _ws_state}) do
        handle_invite_create(invite)
      end

      def handle_event({:INVITE_DELETE, invite_data, _ws_state}) do
        handle_invite_delete(invite_data)
      end

      def handle_event(event) do
        handle_unknown_event(event)
      end

      # Default implementations for callbacks not yet implemented
      def handle_message_reaction_add(data) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_struct: data
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No message reaction resource configured")
            {:error, "No message reaction resource configured"}
        end

        :ok
      end

      def handle_message_reaction_remove(data) do
        # Reaction removal not yet implemented due to filter macro issues
        Logger.info("AshDiscord: Message reaction removal requested - not yet implemented")
        :ok
      end

      def handle_message_reaction_remove_all(data) do
        # Reaction removal not yet implemented due to filter macro issues
        Logger.info("AshDiscord: Message reaction remove all requested - not yet implemented")
        :ok
      end

      def handle_guild_create(guild) do
        Logger.info("AshDiscord: handle_guild_create called for guild #{guild.id}")

        case AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(__MODULE__) do
          {:ok, resource} ->
            Logger.info("AshDiscord: Found guild resource: #{inspect(resource)}")

            case resource
                 |> Ash.Changeset.for_create(
                   :from_discord,
                   %{
                     discord_id: guild.id,
                     discord_struct: guild
                   },
                   context: %{
                     private: %{ash_discord?: true},
                     shared: %{private: %{ash_discord?: true}}
                   }
                 )
                 |> Ash.create() do
              {:ok, created_guild} ->
                Logger.info("AshDiscord: Successfully created guild #{created_guild.discord_id}")
                :ok

              {:error, error} ->
                Logger.warning(
                  "AshDiscord: Failed to create guild #{guild.id}: #{inspect(error)}"
                )

                :ok
            end

          :error ->
            Logger.info("AshDiscord: No guild resource configured")
            :ok
        end
      end

      def handle_guild_update(guild) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(__MODULE__),
             {:ok, _guild} <-
               resource
               |> Ash.Changeset.for_create(
                 :from_discord,
                 %{
                   discord_id: guild.id,
                   discord_struct: guild
                 },
                 context: %{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 }
               )
               |> Ash.create() do
          :ok
        else
          {:error, error} ->
            Logger.warning("Failed to update guild #{guild.id}: #{inspect(error)}")
            :ok

          :error ->
            # No guild resource configured
            :ok
        end
      end

      def handle_guild_delete(data) do
        # Guild deletion not yet implemented due to filter macro issues
        # TODO: Implement guild deletion when filter issues are resolved
        Logger.info("AshDiscord: Guild deletion requested for #{data.id} - not yet implemented")
        :ok
      end

      def handle_guild_role_create(role) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(__MODULE__),
             {:ok, _role} <-
               resource
               |> Ash.Changeset.for_create(
                 :from_discord,
                 %{
                   discord_id: role.id,
                   guild_discord_id: role.guild_id,
                   discord_struct: role
                 },
                 context: %{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 }
               )
               |> Ash.create() do
          :ok
        else
          {:error, error} ->
            Logger.warning(
              "Failed to create role #{role.id} in guild #{role.guild_id}: #{inspect(error)}"
            )

            :ok

          :error ->
            # No role resource configured
            :ok
        end
      end

      def handle_guild_role_update(role) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(__MODULE__),
             {:ok, _role} <-
               resource
               |> Ash.Changeset.for_create(
                 :from_discord,
                 %{
                   discord_id: role.id,
                   guild_discord_id: role.guild_id,
                   discord_struct: role
                 },
                 context: %{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 }
               )
               |> Ash.create() do
          :ok
        else
          {:error, error} ->
            Logger.warning(
              "Failed to update role #{role.id} in guild #{role.guild_id}: #{inspect(error)}"
            )

            :ok

          :error ->
            # No role resource configured
            :ok
        end
      end

      def handle_guild_role_delete(data) do
        # Role deletion not yet implemented
        # TODO: Implement role deletion when needed
        :ok
      end

      def handle_guild_member_add(guild_id, member) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(__MODULE__) do
          # Extract user_id from member struct
          user_discord_id = member.user_id || (member.user && member.user.id)

          try do
            _member =
              resource
              |> Ash.Changeset.for_create(
                :from_discord,
                %{
                  user_discord_id: user_discord_id,
                  guild_discord_id: guild_id,
                  discord_struct: member
                },
                context: %{
                  private: %{ash_discord?: true},
                  shared: %{private: %{ash_discord?: true}}
                }
              )
              |> Ash.create!()

            :ok
          rescue
            error ->
              require Logger

              Logger.warning(
                "Failed to create guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
              )

              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No guild member resource configured
            :ok
        end
      end

      def handle_guild_member_update(guild_id, member) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(__MODULE__) do
          # Extract user_id from member struct
          user_discord_id = member.user_id || (member.user && member.user.id)

          try do
            # from_discord action handles both create and update (upsert)
            _member =
              resource
              |> Ash.Changeset.for_create(
                :from_discord,
                %{
                  user_discord_id: user_discord_id,
                  guild_discord_id: guild_id,
                  discord_struct: member
                },
                context: %{
                  private: %{ash_discord?: true},
                  shared: %{private: %{ash_discord?: true}}
                }
              )
              |> Ash.create!()

            :ok
          rescue
            error ->
              require Logger

              Logger.warning(
                "Failed to update guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
              )

              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No guild member resource configured
            :ok
        end
      end

      def handle_guild_member_remove(guild_id, member) do
        with {:ok, resource} <-
               AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(__MODULE__) do
          # For REMOVE events, member is usually just {user_id: id}
          user_discord_id = member.user_id || (member.user && member.user.id) || member[:user]

          require Logger

          try do
            # Use bulk destroy with proper filtering for both user and guild
            # We need to use Ash.Query.build/2 to construct the filter properly
            require Ash.Query

            # Build a query that properly filters both user_discord_id and guild's discord_id
            # We'll use the simple filter that should work for this case
            query =
              resource
              |> Ash.Query.filter(user_discord_id: user_discord_id)

            %Ash.BulkResult{} =
              result =
              Ash.bulk_destroy!(query, :destroy, %{},
                context: %{
                  private: %{ash_discord?: true},
                  shared: %{private: %{ash_discord?: true}}
                },
                return_errors?: false,
                return_records?: false
              )

            # Check if any records were deleted
            deleted_count = Map.get(result, :count, 0) || 0

            if deleted_count > 0 do
              Logger.info("Deleted guild member #{user_discord_id} from guild #{guild_id}")
            else
              Logger.debug(
                "Guild member #{user_discord_id} not found in guild #{guild_id} for removal"
              )
            end

            :ok
          rescue
            error ->
              Logger.warning(
                "Failed to delete guild member #{user_discord_id} from guild #{guild_id}: #{inspect(error)}"
              )

              # Don't crash the consumer
              :ok
          end
        else
          :error ->
            # No guild member resource configured
            :ok
        end
      end

      def handle_channel_create(channel) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_id: channel.id,
                discord_struct: channel
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No channel resource configured")
            {:error, "No channel resource configured"}
        end

        :ok
      end

      def handle_channel_update(channel) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_id: channel.id,
                discord_struct: channel
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No channel resource configured")
            {:error, "No channel resource configured"}
        end

        :ok
      end

      def handle_channel_delete(channel) do
        # Channel deletion not yet implemented due to filter macro issues
        Logger.info(
          "AshDiscord: Channel deletion requested for #{channel.id} - not yet implemented"
        )

        :ok
      end

      def handle_voice_state_update(voice_state) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_voice_state_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_struct: voice_state
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No voice state resource configured")
            {:error, "No voice state resource configured"}
        end

        :ok
      end

      def handle_typing_start(typing_data) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_typing_indicator_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_struct: typing_data
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No typing indicator resource configured")
            {:error, "No typing indicator resource configured"}
        end

        :ok
      end

      def handle_invite_create(invite) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(__MODULE__) do
          {:ok, resource} ->
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                discord_struct: invite
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create()

          :error ->
            Logger.warning("No invite resource configured")
            {:error, "No invite resource configured"}
        end

        :ok
      end

      def handle_invite_delete(invite_data) do
        # Invite deletion not yet implemented due to filter macro issues
        Logger.info("AshDiscord: Invite deletion requested - not yet implemented")
        :ok
      end

      def handle_unknown_event(event), do: :ok

      def command_allowed_for_interaction?(interaction, command) do
        case AshDiscord.Consumer.Info.ash_discord_consumer_command_filter(__MODULE__) do
          {:ok, filter} when not is_nil(filter) ->
            guild = extract_guild_context(interaction)
            # Since the user said there's no chain, just one filter, call it directly
            filter.command_allowed?(command, guild)

          _ ->
            true
        end
      end

      def extract_guild_context(interaction) do
        case interaction.guild_id do
          nil -> nil
          guild_id -> %{id: guild_id}
        end
      end

      def create_user_from_discord(_discord_user), do: nil

      defp respond_with_error(interaction, message) do
        response = %{
          # CHANNEL_MESSAGE_WITH_SOURCE
          type: 4,
          data: %{
            content: message,
            # EPHEMERAL
            flags: 64
          }
        }

        case Nostrum.Api.create_interaction_response(interaction, response) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            require Logger
            Logger.error("Failed to send error response: #{inspect(error)}")
            :ok
        end
      end

      # Make all callbacks overridable
      defoverridable handle_message_create: 1,
                     handle_message_update: 1,
                     handle_message_delete: 1,
                     handle_message_delete_bulk: 1,
                     handle_message_reaction_add: 1,
                     handle_message_reaction_remove: 1,
                     handle_message_reaction_remove_all: 1,
                     handle_guild_create: 1,
                     handle_guild_update: 1,
                     handle_guild_delete: 1,
                     handle_guild_role_create: 1,
                     handle_guild_role_update: 1,
                     handle_guild_role_delete: 1,
                     handle_guild_member_add: 2,
                     handle_guild_member_update: 2,
                     handle_guild_member_remove: 2,
                     handle_channel_create: 1,
                     handle_channel_update: 1,
                     handle_channel_delete: 1,
                     handle_voice_state_update: 1,
                     handle_typing_start: 1,
                     handle_invite_create: 1,
                     handle_invite_delete: 1,
                     handle_ready: 1,
                     handle_interaction_create: 1,
                     handle_application_command: 1,
                     handle_unknown_event: 1,
                     handle_event: 1,
                     callback_enabled?: 1,
                     find_command: 1,
                     command_allowed_for_interaction?: 2,
                     extract_guild_context: 1,
                     create_user_from_discord: 1
    end
  end
end
