# AshDiscord

> ⚠️ **PRE-ALPHA SOFTWARE** ⚠️
>
> This library is in pre-alpha development and **NOT READY FOR PRODUCTION USE**.
> This codebase was developed through heavy "vibe coding" and requires
> significant cleanup before stable release. APIs will change frequently and
> breaking changes are expected.

[![CI](https://github.com/ash-project/ash_discord/workflows/CI/badge.svg)](https://github.com/ash-project/ash_discord/actions)
[![Integration Tests](https://github.com/ash-project/ash_discord/workflows/Integration%20Tests/badge.svg)](https://github.com/ash-project/ash_discord/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/ash_discord.svg)](https://hex.pm/packages/ash_discord)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/ash_discord/)

**The complete Discord integration library for Ash Framework applications.**

AshDiscord provides seamless Discord bot integration for Ash applications,
enabling you to build powerful Discord bots with declarative command
definitions, automatic parameter validation, and the full power of the Ash
ecosystem.

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
  use AshDiscord.Consumer

  ash_discord_consumer do
    domains [MyBot.Discord]
  end
end

# 4. Start building! 🎉
```

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
  use AshDiscord.Consumer

  ash_discord_consumer do
    domains [GameBot.Discord]
  end
end
```

**Result:** Users can run `/roll` or `/roll sides:20 count:3` and get instant
responses! 🎯

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

AshDiscord provides a cleaner, more maintainable approach to Discord bot
development:

### Simplified Development

- **Declarative command definitions** - no manual Discord API registration
- **Automatic parameter handling** - Ash actions become Discord commands
- **Built-in validation** - leverage Ash's powerful validation system
- **Standard testing patterns** - test Ash actions directly

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

## 🔧 CI/Development

Our project uses a modern dual CI architecture for comprehensive quality
assurance:

### **Centralized CI** (via Ash Ecosystem)

- 🔗 **Centralized Workflow**: Leverages
  `ash-project/ash/.github/workflows/ash-ci.yml@main`
- 🛡️ **Security Scanning**: Sobelow static analysis + hex.audit dependency
  scanning
- ⚡ **Ecosystem Alignment**: Automatic improvements inherited from Ash core
- 📊 **Quality Gates**: Format, Credo, Dialyzer, Spark formatter

### **Integration Testing**

- 🏗️ **Real-World Validation**: Phoenix + Bare Elixir project installation
  testing
- ✅ **Installation Success**: 100% success rate across supported scenarios
- 🔍 **Generated Code**: File creation, configuration, and compilation
  verification

### **Local Development**

```bash
# Run local quality checks
mix quality        # Format, credo, dialyzer
mix test           # Run all tests

# Run specific test files
mix test test/ash_discord/integration_test.exs
```

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for
details on local development setup and testing requirements.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for
details.

Built with ❤️ by the Ash Framework community.

- **[Ash Framework](https://ash-hq.org/)** - The incredible foundation that
  makes this possible
- **[Nostrum](https://github.com/Kraigie/nostrum)** - Excellent Discord library
  for Elixir
- **Community contributors** - Thank you for making AshDiscord better!

---

**Ready to revolutionize your Discord bot development?**

**[🚀 Get Started Now - 30 Minute Quick Start](docs/quick-start-guide.md)**
