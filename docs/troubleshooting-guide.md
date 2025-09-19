# AshDiscord Troubleshooting Guide

This guide helps you diagnose and resolve common issues when integrating AshDiscord into your Discord bot applications.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Configuration Problems](#configuration-problems)
- [Command Registration Issues](#command-registration-issues)
- [Interaction Handling Problems](#interaction-handling-problems)
- [Permission and Authorization Issues](#permission-and-authorization-issues)
- [Performance Issues](#performance-issues)
- [Database Integration Problems](#database-integration-problems)
- [Production Deployment Issues](#production-deployment-issues)
- [Debugging Tips](#debugging-tips)

## Installation Issues

### Issue: Dependency Conflicts

**Problem:** Mix dependency resolution fails with conflicts between Ash, Nostrum, or other dependencies.

```
** (Mix) Hex dependency resolution failed
  ash_discord ~> 0.1.0
  ash ~> 2.21.0  
  nostrum ~> 0.9.0
```

**Solution:**

1. **Check version compatibility:**

```elixir
# mix.exs - Use compatible versions
defp deps do
  [
    {:ash_discord, "~> 0.1.0"},
    {:ash, "~> 3.0"},           # Ensure Ash 3.0+
    {:nostrum, "~> 0.10"},      # Ensure Nostrum 0.10+
    {:jason, "~> 1.4"}
  ]
end
```

2. **Clear dependency cache:**

```bash
mix deps.clean --all
mix deps.get
```

3. **Force specific versions if needed:**

```elixir
defp deps do
  [
    {:ash_discord, "~> 0.1.0"},
    {:ash, "~> 3.0", override: true},
    {:nostrum, "~> 0.10", override: true}
  ]
end
```

### Issue: Missing System Dependencies

**Problem:** Compilation fails with missing system libraries.

```
** (CompileError) could not compile dependency :nostrum
```

**Solution:**

Install required system dependencies:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential erlang-dev

# macOS with Homebrew
brew install autoconf

# Alpine Linux (Docker)
apk add --no-cache build-base
```

## Configuration Problems

### Issue: Bot Token Not Found

**Problem:** Bot fails to start with missing token error.

```
** (RuntimeError) DISCORD_BOT_TOKEN not set
```

**Solution:**

1. **Set environment variable:**

```bash
export DISCORD_BOT_TOKEN="your_bot_token_here"
```

2. **Configure in runtime.exs:**

```elixir
# config/runtime.exs
import Config

config :nostrum,
  token: System.get_env("DISCORD_BOT_TOKEN") || raise("DISCORD_BOT_TOKEN must be set"),
  gateway_intents: [
    :guilds,
    :guild_messages,
    :direct_messages
  ]
```

3. **Verify token format:**

```elixir
# Token should be a long string starting with MTAw... or similar
token = System.get_env("DISCORD_BOT_TOKEN")
IO.puts("Token length: #{String.length(token || "")}")
IO.puts("Token starts with: #{String.slice(token || "", 0, 4)}")
```

### Issue: Invalid Gateway Intents

**Problem:** Bot connects but doesn't receive expected events.

```
# Bot connects but handle_message_create/1 never called
```

**Solution:**

Configure correct gateway intents:

```elixir
# config/runtime.exs
config :nostrum,
  gateway_intents: [
    :guilds,                    # Required for guild events
    :guild_messages,           # Required for message events
    :guild_message_reactions,  # Required for reaction events
    :direct_messages,          # Required for DM support
    :message_content           # Required to read message content (privileged)
  ]
```

**Important:** Message content intent requires bot verification for large bots (100+ servers).

### Issue: Consumer Not Starting

**Problem:** Consumer module doesn't start properly.

```
** (MatchError) no match of right hand side value: {:error, {:already_started, #PID<0.123.0>}}
```

**Solution:**

1. **Check supervision tree:**

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    # Ensure consumer is in children list
    {MyApp.DiscordConsumer, []}
  ]
  
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

2. **Ensure unique consumer names:**

```elixir
# Only one consumer should use AshDiscord.Consumer
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer, domains: [MyApp.Discord]
end
```

3. **Check for multiple Nostrum consumers:**

```elixir
# Don't use both AshDiscord.Consumer and raw Nostrum.Consumer
# Comment out or remove old Nostrum consumer
# defmodule MyApp.OldConsumer do
#   use Nostrum.Consumer
# end
```

## Command Registration Issues

### Issue: Commands Not Appearing in Discord

**Problem:** Bot starts successfully but slash commands don't appear in Discord.

**Diagnostic Steps:**

1. **Check command registration logs:**

```elixir
# Look for this log message on bot startup
# "AshDiscord: Registering X commands with Discord"
# "Successfully registered Discord commands globally"
```

2. **Verify command definitions:**

```elixir
# Test command collection
iex> MyApp.Discord |> AshDiscord.Info.discord_commands() |> length()
3  # Should show expected number of commands

iex> MyApp.Discord |> AshDiscord.Info.discord_commands() |> Enum.map(& &1.name)
[:hello, :weather, :help]  # Should show your command names
```

3. **Check Discord API response:**

```elixir
# Add debugging to consumer
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer, domains: [MyApp.Discord]
  
  def handle_ready(data) do
    Logger.info("Bot ready: #{data.user.username}")
    
    # Manually check command registration
    case Nostrum.Api.get_global_application_commands() do
      {:ok, commands} ->
        Logger.info("Currently registered commands: #{length(commands)}")
        Enum.each(commands, fn cmd -> 
          Logger.info("Command: #{cmd.name}")
        end)
      {:error, error} ->
        Logger.error("Failed to fetch commands: #{inspect(error)}")
    end
    
    :ok
  end
end
```

**Solutions:**

1. **Global vs Guild Commands:**

```elixir
# Commands may take up to 1 hour to appear globally
# For testing, use guild commands instead:
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer, domains: [MyApp.Discord]
  
  # Override command registration for testing
  defp register_discord_commands do
    commands = collect_commands(@ash_discord_domains)
    discord_commands = Enum.map(commands, &to_discord_command/1)
    
    # Register in specific guild for testing (immediate)
    test_guild_id = System.get_env("DISCORD_TEST_GUILD_ID")
    if test_guild_id do
      Nostrum.Api.bulk_overwrite_guild_application_commands(
        String.to_integer(test_guild_id),
        discord_commands
      )
    end
    
    # Also register globally (for production)
    Nostrum.Api.bulk_overwrite_global_application_commands(discord_commands)
  end
end
```

2. **Command Validation Issues:**

```elixir
# Ensure commands pass Discord validation
discord do
  command :test, MyResource, :test_action do
    description "Test command"  # Description is required
    # Name must be lowercase, 1-32 chars, letters/numbers/hyphens only
  end
end
```

### Issue: Command Options Not Auto-Detected

**Problem:** Commands appear but without expected options.

**Diagnostic Steps:**

```elixir
# Check action definition
iex> MyResource.__ash_config__[:actions]
# Should show your action with arguments

# Check command structure
iex> command = MyApp.Discord |> AshDiscord.Info.discord_commands() |> hd()
iex> command.options
# Should show expected options
```

**Solutions:**

1. **Ensure action arguments are public:**

```elixir
defmodule MyResource do
  use Ash.Resource
  
  actions do
    action :my_action, :string do
      # ✅ Arguments are auto-detected
      argument :message, :string, allow_nil?: false
      argument :count, :integer, default: 1
    end
    
    create :create do
      # ✅ Accepted attributes are auto-detected  
      accept [:title, :description]
      
      argument :category, :string  # Also auto-detected
    end
  end

  attributes do
    attribute :title, :string, allow_nil?: false, public?: true     # ✅ Public
    attribute :description, :string, public?: true                 # ✅ Public
    attribute :private_field, :string, public?: false              # ❌ Not auto-detected
  end
end
```

2. **Manual option definition:**

```elixir
# Override auto-detection when needed
discord do
  command :custom, MyResource, :action do
    description "Custom command"
    
    # Manual options override auto-detection
    option :message, :string, required: true, description: "Your message"
    option :count, :integer, description: "How many times to repeat"
    option :private, :boolean, description: "Keep response private"
  end
end
```

### Issue: Command Scope Configuration

**Problem:** Commands appear in wrong servers or take too long to update.

**Solution:**

```elixir
discord do
  default_scope :guild  # Commands appear immediately in guilds
  
  command :admin_only, AdminResource, :admin_action do
    scope :guild  # Only in specific guilds
  end
  
  command :global_help, HelpResource, :help do  
    scope :global  # Available everywhere (slower to propagate)
  end
end
```

## Interaction Handling Problems

### Issue: Commands Execute But Return Errors

**Problem:** Command appears to work but user sees "Application did not respond" or error messages.

**Diagnostic Steps:**

1. **Check action execution:**

```elixir
# Test action directly in IEx
iex> MyResource.my_action(%{argument: "value"}, actor: %{id: "123"})
```

2. **Add debugging to actions:**

```elixir
action :debug_action, :string do
  argument :input, :string, allow_nil?: false
  
  run fn %{arguments: %{input: input}}, context ->
    Logger.info("Action called with input: #{input}")
    Logger.info("Context: #{inspect(context)}")
    
    result = "Hello #{input}"
    Logger.info("Returning result: #{result}")
    
    {:ok, result}
  end
end
```

**Solutions:**

1. **Ensure actions return correct format:**

```elixir
# ✅ Correct return formats
action :string_response, :string do
  run fn _input, _context ->
    {:ok, "This is a string response"}  # Returns string to Discord
  end
end

action :structured_response, :map do
  run fn _input, _context ->
    {:ok, %{
      content: "Response message",
      embeds: [%{title: "Embed Title", description: "Embed Description"}]
    }}
  end
end

# ❌ Incorrect return format
action :broken_response, :string do
  run fn _input, _context ->
    "Direct string return won't work"  # Missing {:ok, result} tuple
  end
end
```

2. **Handle errors properly:**

```elixir
action :safe_action, :string do
  argument :required_input, :string, allow_nil?: false
  
  run fn %{arguments: args}, context ->
    case validate_input(args.required_input) do
      :ok ->
        result = process_input(args.required_input)
        {:ok, result}
      {:error, reason} ->
        # Return user-friendly error message
        {:error, "Invalid input: #{reason}"}
    end
  rescue
    error ->
      Logger.error("Unexpected error in safe_action: #{inspect(error)}")
      {:error, "Something went wrong. Please try again."}
  end
end
```

### Issue: User Context Not Available

**Problem:** Actions fail because user/actor information is not available.

**Solution:**

1. **Implement user creator function:**

```elixir
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer, domains: [MyApp.Discord]
  
  def create_user_from_discord(discord_user) do
    # Create or find user from Discord data
    case MyApp.Accounts.get_user_by_discord_id(discord_user.id) do
      {:ok, user} -> user
      {:error, :not_found} ->
        # Create new user
        MyApp.Accounts.create_user_from_discord!(%{
          discord_id: discord_user.id,
          username: discord_user.username,
          avatar: discord_user.avatar
        })
    end
  end
end
```

2. **Use actor in actions:**

```elixir
action :user_specific_action, :string do
  run fn _input, context ->
    user_id = context.actor.id
    username = context.actor.username
    
    {:ok, "Hello #{username}! Your user ID is #{user_id}"}
  end
end
```

### Issue: Permission Errors

**Problem:** Commands fail with "Forbidden" or authorization errors.

**Solution:**

1. **Check policy configuration:**

```elixir
# Ensure policies allow the action
policies do
  authorize_if always()  # Temporarily allow all for testing
  
  # Then add proper authorization
  # authorize_if actor_attribute_matches(:role, :user)
end
```

2. **Debug authorization:**

```elixir
# Test authorization directly
iex> actor = %{id: "123", role: :user}
iex> MyResource.can_action?(actor, :my_action)
```

## Permission and Authorization Issues

### Issue: Discord Permissions Not Working

**Problem:** Bot has required permissions but still can't perform actions.

**Diagnostic Steps:**

1. **Check bot permissions in Discord:**
   - Go to Server Settings → Roles → Your Bot Role
   - Verify required permissions are enabled
   - Check channel-specific permission overrides

2. **Test permission checking:**

```elixir
# Check bot's permissions in specific guild/channel
case Nostrum.Api.get_guild_member(guild_id, bot_user_id) do
  {:ok, member} ->
    Logger.info("Bot permissions: #{inspect(member.permissions)}")
  {:error, reason} ->
    Logger.error("Cannot get bot permissions: #{inspect(reason)}")
end
```

**Solutions:**

1. **Verify permission requirements:**

```elixir
# Common permissions needed
config :nostrum,
  # Bot needs these application permissions:
  # - Send Messages
  # - Use Slash Commands  
  # - Embed Links (for rich responses)
  # - Attach Files (for file responses)
  # - Read Message History
  # - Add Reactions (if using reactions)
```

2. **Handle permission errors gracefully:**

```elixir
action :send_message, :map do
  argument :channel_id, :string, allow_nil?: false
  argument :content, :string, allow_nil?: false
  
  run fn %{arguments: args}, _context ->
    case Nostrum.Api.create_message(args.channel_id, args.content) do
      {:ok, message} ->
        {:ok, %{message_id: message.id}}
      {:error, %{status_code: 403}} ->
        {:error, "Bot lacks permission to send messages in this channel"}
      {:error, %{status_code: 404}} ->
        {:error, "Channel not found"}
      {:error, reason} ->
        {:error, "Failed to send message: #{inspect(reason)}"}
    end
  end
end
```

### Issue: Ash Authorization Policies

**Problem:** Ash policies blocking legitimate actions.

**Solution:**

1. **Simplify policies for debugging:**

```elixir
policies do
  # Temporarily allow everything
  authorize_if always()
end

# Or add debug policy
policies do
  authorize_if debug_policy()
end

defp debug_policy do
  fn actor, context ->
    Logger.info("Authorization check - Actor: #{inspect(actor)}")
    Logger.info("Authorization check - Context: #{inspect(context)}")
    true  # Always allow for debugging
  end
end
```

2. **Use proper actor structure:**

```elixir
# Ensure actor has expected structure for policies
def create_user_from_discord(discord_user) do
  %{
    id: discord_user.id,
    username: discord_user.username,
    role: :user,  # Used by policies like actor_attribute_equals(:role, :user)
    permissions: [:basic_user],  # Custom permission system
    discord_permissions: discord_user.permissions  # Discord-specific permissions
  }
end
```

## Performance Issues

### Issue: High CPU Usage

**Problem:** Bot consumes excessive CPU, especially during high Discord activity.

**Diagnostic Steps:**

1. **Profile callback usage:**

```elixir
# Check which callbacks are enabled
iex> MyApp.DiscordConsumer.enabled_callbacks()
iex> MyApp.DiscordConsumer.callback_enabled?(:typing_start)
```

2. **Monitor event frequency:**

```elixir
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer
  
  def handle_event(event) do
    # Track event frequency
    :telemetry.execute([:discord, :event], %{count: 1}, %{event_type: elem(event, 0)})
    super(event)
  end
end
```

**Solutions:**

1. **Optimize callback configuration:**

```elixir
# Production consumer with minimal callbacks
defmodule MyApp.ProductionConsumer do  
  use AshDiscord.Consumer,
    domains: [MyApp.Discord],
    callback_config: :production,  # Optimized preset
    disable_callbacks: [
      :typing_events,      # Very frequent, usually not needed
      :voice_events,       # Only needed for voice bots
      :invite_events       # Usually not business critical
    ]
end

# Development consumer with full logging
defmodule MyApp.DevConsumer do
  use AshDiscord.Consumer,
    domains: [MyApp.Discord], 
    callback_config: :development
end
```

2. **Implement smart message filtering:**

```elixir
def handle_message_create(message) do
  # Filter out unnecessary processing
  cond do
    message.author.bot -> :ok  # Ignore bot messages
    String.length(message.content) == 0 -> :ok  # Ignore empty messages
    not bot_mentioned?(message) and message.guild_id -> :ok  # Ignore unless mentioned
    true -> process_message(message)
  end
end
```

### Issue: Memory Leaks

**Problem:** Bot memory usage grows over time.

**Solution:**

1. **Implement periodic cleanup:**

```elixir
# Add cleanup worker to your application
defmodule MyApp.Workers.CleanupWorker do
  use Oban.Worker, queue: :cleanup
  
  @impl Oban.Worker
  def perform(_job) do
    # Clean up old data
    cleanup_old_interactions()
    cleanup_expired_cache()
    :erlang.garbage_collect()  # Force garbage collection
    :ok
  end

  defp cleanup_old_interactions do
    # Remove interactions older than 24 hours
    cutoff = DateTime.add(DateTime.utc_now(), -24, :hour)
    MyApp.Interaction |> Ash.Query.filter(inserted_at < ^cutoff) |> Ash.bulk_destroy!()
  end
end

# Schedule in config
config :my_app, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", MyApp.Workers.CleanupWorker}  # Every hour
     ]}
  ]
```

2. **Monitor memory usage:**

```elixir
# Add memory monitoring  
defmodule MyApp.MemoryMonitor do
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    :timer.send_interval(60_000, :check_memory)  # Check every minute
    {:ok, %{}}
  end
  
  def handle_info(:check_memory, state) do
    memory_mb = :erlang.memory(:total) / (1024 * 1024)
    
    if memory_mb > 500 do  # Alert if over 500MB
      Logger.warn("High memory usage: #{Float.round(memory_mb, 2)}MB")
    end
    
    {:noreply, state}
  end
end
```

## Database Integration Problems

### Issue: Connection Pool Exhaustion

**Problem:** "All connections checked out" errors during high load.

**Solution:**

```elixir
# config/runtime.exs
config :my_app, MyApp.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "20")),  # Increase pool size
  queue_target: 5000,
  queue_interval: 1000
```

### Issue: Database Migration Problems

**Problem:** Ash migrations fail or don't run correctly.

**Solution:**

1. **Use proper Ash migration commands:**

```bash
# Generate migrations for resource changes
mix ash.codegen --name add_new_fields

# Run Ash setup (includes migrations)
mix ash.setup

# Or run migrations directly
mix ash_postgres.migrate
```

2. **Check resource snapshots:**

```bash
# Ensure snapshots are up to date
ls priv/resource_snapshots/repo/

# Regenerate if needed
mix ash.codegen --name regenerate_snapshots
```

### Issue: Query Performance

**Problem:** Database queries are slow, affecting Discord response times.

**Solution:**

1. **Add database indexes:**

```elixir
defmodule MyApp.UserMessage do
  use Ash.Resource, data_layer: AshPostgres.DataLayer
  
  postgres do
    table "user_messages"
    
    # Add indexes for commonly queried fields
    custom_indexes do
      index [:user_id, :inserted_at]  # For user message history
      index [:guild_id, :channel_id]  # For channel queries
    end
  end
end
```

2. **Optimize queries with preloading:**

```elixir
read :messages_with_user do
  # Preload related data to avoid N+1 queries
  prepare build(load: [:user, :channel])
end
```

## Production Deployment Issues

### Issue: Environment Configuration

**Problem:** Bot works in development but fails in production.

**Solution:**

1. **Environment-specific configuration:**

```elixir
# config/runtime.exs
import Config

# Load .env file in development
if config_env() == :dev do
  import_config "dev.secret.exs"  # Contains DISCORD_BOT_TOKEN
end

# Production configuration
if config_env() == :prod do
  # All config from environment variables
  config :nostrum,
    token: System.get_env("DISCORD_BOT_TOKEN") || raise("DISCORD_BOT_TOKEN required"),
    gateway_intents: [
      :guilds,
      :guild_messages,
      :direct_messages
    ]
    
  config :my_app, MyApp.Repo,
    url: System.get_env("DATABASE_URL") || raise("DATABASE_URL required"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
    ssl: true,
    ssl_opts: [verify: :verify_none]
end
```

2. **Container-specific issues:**

```dockerfile
# Dockerfile
FROM elixir:1.15-alpine

# Install required system dependencies
RUN apk add --no-cache build-base git

WORKDIR /app

# Copy and install dependencies
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod

# Copy source and compile
COPY . .
RUN mix compile

# Run migrations on startup
CMD ["sh", "-c", "mix ash.setup && mix run --no-halt"]
```

### Issue: SSL Certificate Problems

**Problem:** Database connections fail with SSL errors in production.

**Solution:**

```elixir
# config/runtime.exs
config :my_app, MyApp.Repo,
  url: database_url,
  ssl: true,
  ssl_opts: [
    verify: :verify_peer,
    cacertfile: CAStore.file_path(),
    server_name_indication: String.to_charlist(database_hostname),
    customize_hostname_check: [
      match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
    ]
  ]

# Or for development/testing
config :my_app, MyApp.Repo,
  ssl_opts: [verify: :verify_none]  # Less secure but works
```

## Debugging Tips

### Enable Debug Logging

```elixir
# config/runtime.exs
config :logger, level: :debug

# In your consumer
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer, 
    domains: [MyApp.Discord],
    debug_logging: true
end
```

### IEx Debugging

```elixir
# Start your app with IEx
iex -S mix

# Test commands directly
iex> actor = %{id: "123456789", role: :user}
iex> MyApp.MyResource.my_action(%{argument: "test"}, actor: actor)

# Check Discord connection
iex> Nostrum.Cache.Me.get()
iex> Nostrum.Api.get_current_user()

# Inspect command definitions
iex> MyApp.Discord |> AshDiscord.Info.discord_commands()
```

### Add Telemetry

```elixir
# Track Discord events
:telemetry.attach_many(
  "discord-events",
  [
    [:discord, :command, :start],
    [:discord, :command, :stop],
    [:discord, :command, :exception]
  ],
  &MyApp.Telemetry.handle_event/4,
  nil
)

# In your consumer
def handle_application_command(interaction) do
  :telemetry.span([:discord, :command], %{command: interaction.data.name}, fn ->
    result = super(interaction)
    {result, %{}}
  end)
end
```

### Test Mode

```elixir
# Create a test consumer that doesn't connect to Discord
defmodule MyApp.TestConsumer do
  use AshDiscord.Consumer, domains: [MyApp.Discord]
  
  # Don't actually connect in test
  def child_spec(_opts) when Mix.env() == :test do
    %{id: __MODULE__, start: {Agent, :start_link, [fn -> :ok end]}}
  end
end
```

### Health Checks

```elixir
# Add health check endpoint
defmodule MyApp.HealthCheck do
  def check do
    %{
      discord_connected: discord_connected?(),
      database_connected: database_connected?(),
      commands_registered: commands_registered?()
    }
  end
  
  defp discord_connected? do
    case Nostrum.Cache.Me.get() do
      %Nostrum.Struct.User{} -> true
      _ -> false
    end
  end
  
  defp database_connected? do
    try do
      MyApp.Repo.query!("SELECT 1")
      true
    rescue
      _ -> false
    end
  end
  
  defp commands_registered? do
    case Nostrum.Api.get_global_application_commands() do
      {:ok, commands} when length(commands) > 0 -> true
      _ -> false
    end
  end
end
```

## Getting Help

If you're still experiencing issues after trying these solutions:

1. **Check the logs** - Enable debug logging and look for error messages
2. **Test in isolation** - Test individual components (actions, resources) separately
3. **Check Discord Developer Portal** - Verify bot permissions and application settings
4. **Review the documentation** - [API Reference](./api-reference.md), [Best Practices](./best-practices-guide.md)
5. **Create a minimal reproduction** - Strip down to the simplest case that reproduces the issue
6. **Check dependency versions** - Ensure you're using compatible versions of Ash, Nostrum, and AshDiscord

Remember: Most issues stem from configuration problems, permission issues, or misunderstanding of the Ash action system. Start with the basics and work your way up to more complex scenarios.