# AshDiscord

[![CI](https://github.com/ash-project/ash_discord/workflows/CI/badge.svg)](https://github.com/ash-project/ash_discord/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/ash_discord.svg)](https://hex.pm/packages/ash_discord)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/ash_discord/)

**The complete Discord integration library for Ash Framework applications.**

AshDiscord provides seamless Discord bot integration for Ash applications, enabling you to build powerful Discord bots with declarative command definitions, automatic parameter validation, and the full power of the Ash ecosystem.

## 🚀 Quick Start (30-Minute Setup)

```elixir
# 1. Add to mix.exs
{:ash_discord, "~> 0.1.0"}

# 2. Create your domain
defmodule MyBot.Discord do
  use Ash.Domain, extensions: [AshDiscord]

  discord do
    command :hello, MyBot.Greeting, :hello do
      description "Say hello to Discord"
    end
  end
end

# 3. Create your consumer  
defmodule MyBot.DiscordConsumer do
  use AshDiscord.Consumer, domains: [MyBot.Discord]
end

# 4. Start building! 🎉
```

**[👉 Complete Quick Start Guide](docs/quick-start-guide.md)** - Get your bot running in under 30 minutes

## ✨ Key Features

### 🎯 **Declarative Command Definitions**
Define Discord slash commands using Ash's powerful DSL syntax:

```elixir
discord do
  command :weather, WeatherResource, :get_weather do
    description "Get weather for any location"
    # Options auto-detected from Ash action arguments!
  end
end
```

### ⚡ **Auto-Detection & Validation** 
- **Command options automatically inferred** from Ash action inputs
- **Built-in parameter validation** using Ash's validation system  
- **Type-safe Discord interactions** with intelligent type mapping
- **Compile-time command validation** catches errors early

### 🔧 **Advanced Consumer System**
- **Selective callback processing** - configure which Discord events to handle
- **Environment-aware defaults** (production, development, test profiles)
- **Zero-overhead disabled events** - unused callbacks have no impact
- **Extensible architecture** with 20+ overridable callbacks

### 🏗️ **Ash Framework Integration**
- **Direct routing** from Discord interactions to Ash actions
- **Built-in authorization** using Ash policies
- **Rich error handling** with user-friendly Discord responses
- **Background job support** via AshOban integration

## 📖 Complete Documentation

| Document | Purpose | Time to Complete |
|----------|---------|------------------|
| **[Quick Start Guide](docs/quick-start-guide.md)** | Get your first bot running | 30 minutes |
| **[API Reference](docs/api-reference.md)** | Complete API documentation | Reference |
| **[Migration Guide](docs/migration-guide.md)** | Migrate from raw Nostrum | 1-2 hours |
| **[Troubleshooting Guide](docs/troubleshooting-guide.md)** | Solve common issues | As needed |

## 🎮 Live Example

Here's a complete, working Discord bot in just a few lines:

```elixir
# Resource with business logic
defmodule GameBot.DiceRoller do
  use Ash.Resource, otp_app: :game_bot, data_layer: :embedded

  actions do
    action :roll, :string do
      argument :sides, :integer, default: 6
      argument :count, :integer, default: 1
      
      run fn %{arguments: %{sides: sides, count: count}}, _context ->
        rolls = Enum.map(1..count, fn _ -> :rand.uniform(sides) end)
        result = "🎲 Rolled #{inspect(rolls)} (#{Enum.sum(rolls)} total)"
        {:ok, result}
      end
    end
  end
end

# Domain with Discord commands
defmodule GameBot.Discord do  
  use Ash.Domain, extensions: [AshDiscord]

  discord do
    command :roll, GameBot.DiceRoller, :roll do
      description "Roll dice with customizable sides and count"
      # Options auto-detected:
      # - sides: integer (optional, default: 6) 
      # - count: integer (optional, default: 1)
    end
  end

  resources do
    resource GameBot.DiceRoller
  end
end

# Consumer that handles everything automatically
defmodule GameBot.DiscordConsumer do
  use AshDiscord.Consumer, 
    domains: [GameBot.Discord],
    callback_config: :production  # Optimized for performance
end
```

**Result:** Users can run `/roll` or `/roll sides:20 count:3` and get instant responses! 🎯

## 🔄 Migration from Nostrum

Migrating from raw Nostrum? AshDiscord provides significant benefits:

| Aspect | Raw Nostrum | AshDiscord | Benefit |
|--------|------------|------------|-------------|
| **Lines of Code** | ~200 lines/command | ~15 lines/command | **Much less boilerplate** |
| **Parameter Handling** | Manual parsing & validation | Automatic via Ash | **Eliminated completely** |
| **Error Handling** | Custom Discord responses | Built-in user-friendly errors | **Standardized** |
| **Testing** | Complex interaction mocking | Standard Ash action testing | **Much simpler** |
| **Performance** | Processes all Discord events | Selective event processing | **Configurable overhead** |

## 💡 Why AshDiscord?

### 🏗️ **Built for Scale**
- **Configurable processing** - selective callback processing for your needs
- **Memory efficient** - compile-time command definitions with zero runtime impact
- **Production ready** - comprehensive error handling, health checks, and monitoring

### 🧪 **Developer Experience** 
- **30-minute setup** - from zero to working bot in under 30 minutes
- **Type safety** - compile-time validation prevents runtime Discord errors  
- **Rich debugging** - comprehensive logging and diagnostic tools
- **Testing made easy** - standard Ash testing patterns work seamlessly

### 🎯 **Community & Standards**
- **Follows Ash patterns** - consistent with Ash.Info, authorization, and action design
- **Industry best practices** - implements proven Discord bot patterns
- **Comprehensive documentation** - guides for every use case and skill level

## 🛠️ Installation

Add to your `mix.exs`:

```elixir
defp deps do
  [
    {:ash_discord, "~> 0.1.0"},
    {:ash, "~> 3.0"},
    {:nostrum, "~> 0.10"}
  ]
end
```

## 🎯 What You Get

AshDiscord provides a cleaner, more maintainable approach to Discord bot development:

### Simplified Development
- **Declarative command definitions** - no manual Discord API registration
- **Automatic parameter handling** - Ash actions become Discord commands
- **Built-in validation** - leverage Ash's powerful validation system
- **Standard testing patterns** - test Ash actions directly

### Selective Event Processing
- **Configure what you need** - only handle events your bot cares about
- **Environment profiles** - different configurations for development vs production
- **Zero overhead for unused events** - disabled callbacks have no impact

## 🌟 Advanced Features

### Context Menu Commands
```elixir
command :user_info, UserResource, :get_info do
  description "Get user information"  
  type :user  # Right-click context menu on users
end

command :moderate_message, ModerationResource, :review do
  description "Review this message"
  type :message  # Right-click context menu on messages  
end
```

### Background Job Integration
```elixir
action :generate_report, :map do
  argument :report_type, :string, allow_nil?: false
  
  run fn args, context ->
    # Queue background job with AshOban
    ReportWorker.new(args) |> Oban.insert()
    {:ok, %{status: "Report queued, you'll receive it shortly!"}}
  end
end
```

### Advanced Authorization
```elixir
policies do
  # Discord-specific permission checking
  authorize_if actor_has_discord_permission(:manage_messages)
  authorize_if actor_attribute_equals(:role, :moderator)
  
  # Complex guild-based rules
  authorize_if expr(
    exists(guild_members, user_id == ^actor(:id) and role == "admin")
  )
end
```

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## 🏢 Production Ready

AshDiscord provides the tools needed for production Discord bots:
- **Comprehensive error handling** with user-friendly messages
- **Configurable event processing** for optimal resource usage  
- **Built-in logging and monitoring** for operational visibility
- **Robust testing patterns** for reliable deployments

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Credits

Built with ❤️ by the Ash Framework community.

- **[Ash Framework](https://ash-hq.org/)** - The incredible foundation that makes this possible
- **[Nostrum](https://github.com/Kraigie/nostrum)** - Excellent Discord library for Elixir
- **Community contributors** - Thank you for making AshDiscord better!

---

**Ready to revolutionize your Discord bot development?** 

**[🚀 Get Started Now - 30 Minute Quick Start](docs/quick-start-guide.md)**