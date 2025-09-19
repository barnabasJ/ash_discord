# AshDiscord Quick Start Guide

Get your Discord bot running with AshDiscord in under 30 minutes! This guide covers everything from installation to your first working slash command.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Discord Bot Setup](#discord-bot-setup)
- [Basic Configuration](#basic-configuration)
- [Your First Command](#your-first-command)
- [Testing Your Bot](#testing-your-bot)
- [Next Steps](#next-steps)

## Prerequisites

Before starting, ensure you have:

- **Elixir 1.14+** and **Erlang/OTP 25+**
- **Phoenix 1.7+** (optional but recommended)
- **Ash Framework 3.0+**
- Basic familiarity with Elixir and Discord

## Installation

Add AshDiscord to your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:ash_discord, "~> 0.1.0"},
    {:ash, "~> 3.0"},
    {:nostrum, "~> 0.10"},
    {:jason, "~> 1.4"}
  ]
end
```

Run the installation:

```bash
mix deps.get
```

## Discord Bot Setup

### 1. Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **"New Application"**
3. Name your application (e.g., "MyBot")
4. Go to **"Bot"** section
5. Click **"Add Bot"**
6. Copy the **Bot Token** (keep this secure!)

### 2. Set Bot Permissions

In the **"OAuth2" → "URL Generator"** section:

1. **Scopes**: Select `bot` and `applications.commands`
2. **Bot Permissions**: Select:
   - Send Messages
   - Use Slash Commands  
   - Read Message History
   - Connect (if using voice)

3. Copy the generated URL and use it to invite your bot to a test server.

### 3. Environment Configuration

Add your bot token to your environment:

```bash
# .env or config/runtime.exs
export DISCORD_BOT_TOKEN="your_bot_token_here"
```

```elixir
# config/runtime.exs
config :nostrum,
  token: System.get_env("DISCORD_BOT_TOKEN")
```

## Basic Configuration

### 1. Create Your Domain

Create a new Ash domain for Discord functionality:

```elixir
# lib/my_app/discord.ex
defmodule MyApp.Discord do
  use Ash.Domain, extensions: [AshDiscord]

  discord do
    # Commands will be added here
  end

  resources do
    # Resources will be added here
  end
end
```

### 2. Create Your First Resource

```elixir
# lib/my_app/discord/greeting.ex  
defmodule MyApp.Discord.Greeting do
  use Ash.Resource, otp_app: :my_app, data_layer: :embedded

  actions do
    # Simple hello command - no parameters
    action :hello, :string do
      run fn _input, _context ->
        {:ok, "👋 Hello from AshDiscord! Welcome to the future of Discord bots!"}
      end
    end

    # Personalized greeting with user parameter
    action :greet_user, :string do
      argument :user_id, :string, allow_nil?: false
      
      run fn %{arguments: %{user_id: user_id}}, _context ->
        {:ok, "🎉 Hello <@#{user_id}>! Thanks for trying AshDiscord!"}
      end
    end

    # Echo command with message parameter  
    action :echo, :string do
      argument :message, :string, allow_nil?: false
      argument :times, :integer, default: 1
      
      run fn %{arguments: %{message: message, times: times}}, _context ->
        repeated = String.duplicate("#{message} ", times) |> String.trim()
        {:ok, "📢 #{repeated}"}
      end
    end
  end

  # No attributes needed for embedded resource actions
end
```

### 3. Add Commands to Your Domain

```elixir
# lib/my_app/discord.ex
defmodule MyApp.Discord do
  use Ash.Domain, extensions: [AshDiscord]

  discord do
    # Simple command with no options
    command :hello, MyApp.Discord.Greeting, :hello do
      description "Get a friendly greeting from the bot"
    end

    # Command with user option (auto-detected from action arguments)
    command :greet, MyApp.Discord.Greeting, :greet_user do
      description "Get a personalized greeting"
      # Options are auto-detected from action arguments:
      # - user_id becomes :user option (required)
    end

    # Command with multiple options
    command :echo, MyApp.Discord.Greeting, :echo do  
      description "Echo your message back to you"
      # Auto-detected options:
      # - message: :string (required)
      # - times: :integer (optional, default: 1)
    end
  end

  resources do
    resource MyApp.Discord.Greeting
  end
end
```

### 4. Create Your Discord Consumer

```elixir
# lib/my_app/discord_consumer.ex
defmodule MyApp.DiscordConsumer do
  use AshDiscord.Consumer,
    domains: [MyApp.Discord],
    callback_config: :development  # Full logging for development

  require Logger

  # Optional: Add custom behavior
  def handle_ready(data) do
    Logger.info("🚀 MyApp Discord Bot is ready! Logged in as: #{data.user.username}")
    :ok
  end

  def handle_message_create(message) do
    # Optional: Respond to text messages
    if String.contains?(message.content, "!ping") and not message.author.bot do
      Nostrum.Api.create_message(message.channel_id, "🏓 Pong!")
    end
    :ok
  end
end
```

### 5. Update Your Application

Add the consumer to your supervision tree:

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... your existing children ...
      
      # Add Discord consumer
      {MyApp.DiscordConsumer, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Your First Command

Let's break down what happens when a user runs `/hello`:

### 1. Command Definition

```elixir
# In your domain
command :hello, MyApp.Discord.Greeting, :hello do
  description "Get a friendly greeting from the bot"
end
```

This creates a Discord slash command that:
- Shows as `/hello` in Discord
- Has description "Get a friendly greeting from the bot"
- Routes to `MyApp.Discord.Greeting.hello/1` action

### 2. Action Implementation  

```elixir
# In your resource
action :hello, :string do
  run fn _input, _context ->
    {:ok, "👋 Hello from AshDiscord! Welcome to the future of Discord bots!"}
  end
end
```

This action:
- Takes no arguments (simple greeting)
- Returns a string response
- AshDiscord automatically formats it for Discord

### 3. Auto-Registration

When your bot starts, AshDiscord automatically:
1. Collects all commands from your domains
2. Registers them with Discord's API
3. Sets up routing from interactions to Ash actions

## Testing Your Bot

### 1. Start Your Application

```bash
# Make sure your environment has the Discord token
export DISCORD_BOT_TOKEN="your_token_here"

# Start your application  
mix phx.server
# or
iex -S mix
```

### 2. Check the Logs

You should see:

```
🚀 MyApp Discord Bot is ready! Logged in as: YourBotName
AshDiscord: Registering 3 commands with Discord
Successfully registered Discord commands globally
```

### 3. Test Commands in Discord

In your Discord server where the bot is invited:

1. Type `/` and you should see your commands appear
2. Try `/hello` - should get a greeting response
3. Try `/greet @someone` - should get a personalized greeting  
4. Try `/echo hello` or `/echo hello 3` - should echo your message

### 4. Test Text Commands (Optional)

If you implemented the message handler:

1. Type `!ping` in any channel
2. Bot should respond with "🏓 Pong!"

## Next Steps

Congratulations! Your bot is running. Here's what to explore next:

### Expand Your Commands

```elixir
# Add more complex commands
command :weather, MyApp.Weather, :get_weather do
  description "Get weather for a location"
  option :location, :string, required: true, description: "City name"
end

command :user_info, MyApp.Users, :get_info do  
  description "Get information about a user"
  type :user  # Context menu command (right-click on user)
end
```

### Add Database Persistence

```elixir
# Switch from :embedded to real database
defmodule MyApp.Discord.Message do
  use Ash.Resource, 
    otp_app: :my_app, 
    data_layer: AshPostgres.DataLayer

  postgres do
    table "discord_messages"
    repo MyApp.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :content, :string
    attribute :discord_id, :string
    attribute :channel_id, :string
  end
end
```

### Advanced Consumer Features

```elixir
defmodule MyApp.ProductionConsumer do
  use AshDiscord.Consumer,
    domains: [MyApp.Discord],
    callback_config: :production,        # Optimized for production
    disable_callbacks: [:typing_events], # Skip noisy events
    auto_create_users: true              # Create users from interactions

  def create_user_from_discord(discord_user) do
    # Custom user creation logic
    MyApp.Accounts.get_or_create_user(%{
      discord_id: discord_user.id,
      username: discord_user.username
    })
  end
end
```

### Error Handling

```elixir
discord do  
  error_strategy :user_friendly  # Show friendly errors to users
  
  command :divide, Calculator, :divide do
    description "Divide two numbers"
    option :a, :number, required: true  
    option :b, :number, required: true
  end
end

# In your action
action :divide, :number do
  argument :a, :float, allow_nil?: false
  argument :b, :float, allow_nil?: false

  run fn %{arguments: %{a: a, b: b}}, _context ->
    if b == 0 do
      {:error, "Cannot divide by zero! 🙈"}
    else
      {:ok, a / b}
    end
  end
end
```

### Explore Advanced Features

- **Context Menu Commands** - Right-click actions on users/messages
- **Command Filtering** - Restrict commands to specific servers/users
- **Background Jobs** - Handle long-running operations
- **Message Components** - Buttons, select menus, modals
- **Webhooks** - Custom message formatting and avatars

## Need Help?

- **Documentation**: [Full API Reference](./api-reference.md)
- **Migration Guide**: [Migrating from Nostrum](./migration-guide.md)
- **Best Practices**: [Best Practices Guide](./best-practices-guide.md)
- **Troubleshooting**: [Common Issues](./troubleshooting-guide.md)

## Example Repository

Check out the complete example in the `examples/` directory:

```bash
git clone https://github.com/ash-project/ash_discord
cd ash_discord/examples/basic_bot
mix deps.get
# Set DISCORD_BOT_TOKEN environment variable
mix phx.server
```

You now have a fully functional Discord bot powered by AshDiscord! The combination of Ash's powerful domain modeling with Discord's rich interaction system opens up endless possibilities for your bot. Happy coding! 🚀