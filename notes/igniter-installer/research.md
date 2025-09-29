# Codebase Impact Analysis: AshDiscord Igniter Installer

## Project Dependencies Discovered

**From ash_discord/mix.exs:**

- **Core dependencies**: ash ~> 3.0, spark ~> 2.0, nostrum ~> 0.10 (runtime:
  Mix.env() != :test)
- **Development dependencies**: igniter ~> 0.6 (only: [:dev, :test])
- **Testing framework**: ExUnit with mimic ~> 1.7, faker ~> 0.18, excoveralls ~>
  0.18
- **Documentation**: ex_doc ~> 0.34
- **Code quality**: credo ~> 1.7, dialyxir ~> 1.4
- **Existing patterns**: Ash Framework 3.0+ extensions with Spark DSL

**Key Libraries and Versions:**

- 📖 [Igniter 0.6 Documentation](https://hexdocs.pm/igniter/Igniter.html) - Code
  generation and modification framework
- 📖 [Ash 3.0 Documentation](https://hexdocs.pm/ash/Ash.html) - Main framework
  for business logic
- 📖 [Spark 2.0 Documentation](https://hexdocs.pm/spark/Spark.html) - DSL
  extension framework
- 📖 [Nostrum 0.10 Documentation](https://hexdocs.pm/nostrum/Nostrum.html) -
  Discord API library

## Files Requiring Changes for Igniter Installer

### **Primary Implementation Files**

**`lib/mix/tasks/ash_discord.install.ex`** - New file needed

- Implementation: Igniter Mix task for AshDiscord installation
- Functions: Consumer generation, dependency management, application
  configuration
- 📖
  [Igniter.Mix.Task behavior](https://hexdocs.pm/igniter/Igniter.Mix.Task.html#callbacks) -
  Task implementation patterns

**`mix.exs:49`** - Add igniter dependency to public deps

- Current: `{:igniter, "~> 0.6", only: [:dev, :test]}`
- Required: Move to main dependencies or make optional: true for runtime
  availability
- 📖 [Mix Dependencies](https://hexdocs.pm/mix/Mix.Tasks.Deps.html) - Dependency
  configuration

### **Supporting Integration Files**

**Consumer Module Template** - Pattern needed for generation

- Based on: `/home/joba/sandbox/steward/lib/steward/discord_consumer.ex:11`
- Pattern: `use AshDiscord.Consumer` with `ash_discord_consumer` DSL block
- Integration: Domains and resource configuration through DSL

**Application Configuration** - Direct integration pattern

- Based on: `/home/joba/sandbox/steward/lib/steward/application.ex:42-43`
- Pattern: Direct consumer addition to supervision tree children
- Integration: Use `Igniter.Project.Application.add_new_child` for proper
  supervision tree modification

## Existing Patterns Found

### **AshDiscord Consumer Pattern (Updated)**

Project follows updated consumer-based architecture with DSL configuration:

- **Consumer Declaration**: `use AshDiscord.Consumer`
- **DSL Configuration**: `ash_discord_consumer` block with domain and resource
  settings
- **Example found in**:
  `/home/joba/sandbox/steward/lib/steward/discord_consumer.ex:15-31`
- **Domain specification**: `domains([App.Domain1, App.Domain2])` in DSL block
- **Resource mapping**: Automatic Discord event handling via resource
  configuration
- 📖
  [AshDiscord.Consumer documentation](https://hexdocs.pm/ash_discord/AshDiscord.Consumer.html) -
  Consumer behavior

### **Application Integration Pattern (Simplified)**

**Direct Supervisor Integration**: Applications add Discord consumer directly to
supervision tree

- **Pattern found in**:
  `/home/joba/sandbox/steward/lib/steward/application.ex:42-43`
- **Direct addition**: Consumer inserted before endpoint in supervision tree
- **No conditional logic**: Consumer always included when installed
- 📖
  [Supervisor child specifications](https://hexdocs.pm/elixir/Supervisor.html#child_spec/1) -
  Child specification format

### **Domain Extension Pattern**

**Ash Domain Extensions**: AshDiscord extends domains via Spark DSL

- **Extension usage**: `use Ash.Domain, extensions: [AshDiscord]`
- **Command definition**: DSL for Discord slash commands in domain modules
- **Example structure**: Found in
  `/home/joba/sandbox/ash_discord/lib/ash_discord.ex:13-22`

## Integration Points

### **Supervision Tree Integration**

**Required changes in target application:**

- **Application module**: Add consumer using
  `Igniter.Project.Application.add_new_child`
- **Direct integration**: No conditional logic needed - always include when
  installed
- **Igniter utilities**: Use proper Igniter functions for supervision tree
  modification

### **Configuration Requirements**

**Config files setup needed:**

- **Discord token**: Bot token configuration for Nostrum in config files
- **Application config**: Basic Discord and Nostrum configuration
- **Environment-specific configs**: Development, test, and runtime
  configurations

### **Dependency Management**

**Mix.exs modifications needed:**

- **Nostrum dependency**: Core Discord library for bot functionality
- **AshDiscord dependency**: The library being installed
- **Version compatibility**: Ensure compatible versions with target application

## Test Impact & Patterns

### **Testing Framework Compatibility**

**Current testing approach**: ExUnit with AshDiscord-specific patterns

- **Test support modules**: Found in
  `/home/joba/sandbox/ash_discord/test/support/`
- **Mock strategies**: Uses Mimic for Discord API mocking in tests
- **Faker integration**: Discord data generation for test fixtures

### **Installer Testing Requirements**

**Tests requiring updates**: Installer behavior validation

- **Mix task testing**: Verify installer creates correct files and
  configurations
- **Integration testing**: Ensure generated consumer works with provided domains
- **Dependency verification**: Confirm all required dependencies are properly
  added

## Configuration & Environment

### **Config Files to Update**

**Application configuration files:**

- **`config/config.exs`**: Base Discord/Nostrum configuration
- **`config/dev.exs`**: Development-specific Discord settings
- **`config/test.exs`**: Test environment Discord configuration
- **`config/runtime.exs`**: Production Discord token configuration

### **Environment Variables**

**Required environment variables:**

- **`DISCORD_TOKEN`**: Bot token for authentication
- **Optional settings**: Debug logging, feature flags

### **Application Configuration Structure**

**Config structure pattern:**

```elixir
# config/config.exs
config :nostrum,
  token: {:system, "DISCORD_TOKEN"}

# config/dev.exs
config :nostrum,
  token: "your_dev_bot_token_here"

# config/runtime.exs
config :nostrum,
  token: System.get_env("DISCORD_TOKEN")
```

## Reference Implementation Analysis

### **ash_authentication.install patterns**

**Key installer patterns from ash_authentication.install.ex:**

- **Igniter.Mix.Task behavior**: Standard task structure with `info/2` and
  `igniter/1` callbacks
- **Domain/Resource generation**: Uses `Igniter.compose_task` for ash.gen.domain
  and ash.gen.resource
- **Igniter.Project.Application.add_new_child**: Adds supervisor children
  automatically
- **Dependency management**: Adds required dependencies with
  `Igniter.Project.Deps.add_dep`
- **Configuration setup**: Uses `Igniter.Project.Config.configure` for
  environment configs
- **Module creation**: Generates supporting modules automatically
- 📖 [Ash.Igniter.codegen](https://hexdocs.pm/ash/Ash.Igniter.html#codegen/2) -
  Ash-specific code generation

### **ash_authentication_phoenix.install patterns**

**Key installer patterns from ash_authentication_phoenix.install.ex:**

- **Dependency composition**: Composes with ash_authentication.install for base
  setup
- **Router modification**: Uses `Igniter.Libs.Phoenix` for router updates
- **Phoenix integration**: Creates controllers, live views, and authentication
  modules
- **Configuration management**: Comprehensive config file updates
- **Module generation**: Creates supporting modules and helpers
- 📖
  [Igniter.Libs.Phoenix](https://hexdocs.pm/igniter/Igniter.Libs.Phoenix.html) -
  Phoenix-specific igniter utilities

### **Steward Integration Requirements Analysis**

**Discord Consumer Integration Patterns from steward (updated):**

- **Consumer module**: Uses `AshDiscord.Consumer` with DSL configuration block
- **DSL Configuration**: `ash_discord_consumer` block with domains and resource
  settings
- **Application integration**: Direct addition to supervision tree without
  conditional logic
- **Automatic handling**: Discord events automatically processed based on
  resource configuration
- **Resource mapping**: Each Discord entity type mapped to corresponding Ash
  resource

## Required New Dependencies/Patterns

### **Runtime Dependencies**

**Required for Discord functionality:**

- **Nostrum**: Must be added to target application dependencies
- **AshDiscord**: The library being installed
- **Compatible versions**: Ensure version compatibility with existing
  dependencies

### **Configuration Dependencies**

**Required configuration setup:**

- **Discord token**: Bot authentication token in config files
- **Nostrum configuration**: Basic Discord API configuration
- **Development settings**: Dev/test specific configurations

## Risk Assessment

### **Breaking Changes**

**Low risk changes:**

- **Consumer generation**: New file creation with minimal application impact
- **Configuration addition**: Additive configuration changes to config files
- **Dependency addition**: Standard mix dependency patterns

### **Performance Implications**

**Resource considerations:**

- **Nostrum supervision**: Additional OTP processes for Discord connectivity
- **Event processing**: Discord event handling adds processing overhead
- **Memory usage**: Discord cache and message processing requires memory

### **Security Touchpoints**

**Security considerations:**

- **Discord token**: Sensitive credential management in configuration files
- **Bot permissions**: Discord bot permissions affect security surface
- **Message processing**: User input validation in Discord interactions

### **Migration Complexity**

**Installation complexity assessment:**

- **Low complexity**: Single installer task for complete setup
- **Moderate integration**: Requires application restart for Discord
  functionality
- **Documentation needs**: Clear setup instructions for Discord bot creation

## Third-Party Integrations & External Services

**Service Detection Results:**

- **Detected services**: Discord API (primary integration)
- **Integration types**: WebSocket gateway connection, REST API calls, Bot
  authentication
- **Integration patterns**: Event-driven consumer, command registration,
  interaction handling

### **Discord API Integration**

**Discord** - Bot Integration and Command Handling

- **Integration Type**: Discord Bot with slash command support and event
  processing
- **Current Status**: Found in codebase at
  `/home/joba/sandbox/ash_discord/lib/ash_discord/consumer.ex` - EXISTING
  INTEGRATION
- **Context-Specific Documentation Links**:
  - 📖 [Discord Developer Documentation](https://discord.com/developers/docs) -
    Complete API reference
  - 📖
    [Discord Bot Authentication](https://discord.com/developers/docs/topics/oauth2#bots) -
    Bot token authentication
  - 📖
    [Slash Commands Guide](https://discord.com/developers/docs/interactions/application-commands) -
    Command registration and handling
  - 📖
    [Discord Gateway Events](https://discord.com/developers/docs/topics/gateway#gateway-events) -
    WebSocket event types
  - 📖 [Nostrum Documentation](https://hexdocs.pm/nostrum/readme.html) - Elixir
    Discord library
  - 📖
    [Discord Interaction Types](https://discord.com/developers/docs/interactions/receiving-and-responding) -
    Interaction handling patterns
  - 📖
    [Bot Permissions](https://discord.com/developers/docs/topics/permissions) -
    Permission configuration
- **Security Considerations**:
  - Bot token storage and rotation
  - Interaction signature verification (handled by Nostrum)
  - Rate limiting and quota management
  - Guild-based permission scoping
- **Version Information**: Current integration
  - Current version: nostrum ~> 0.10 in ash_discord mix.exs
  - 📖 [Nostrum Changelog](https://github.com/Kraigie/nostrum/releases) -
    Version updates and breaking changes
  - Integration status: Mature - used in production applications

**Integration Dependencies:**

- Discord API requires valid bot token for authentication
- Bot must be invited to guilds with appropriate permissions
- Slash commands require application command registration

## Installation Implementation Strategy

Based on the analysis, the installer should follow these patterns:

### **Phase 1: Dependency Setup**

1. **Add nostrum dependency** to target application
2. **Verify ash and spark** versions are compatible
3. **Add AshDiscord** to application dependencies

### **Phase 2: Consumer Generation**

1. **Generate Discord consumer module** using DSL configuration pattern
2. **Configure domains** parameter in ash_discord_consumer block
3. **Add consumer directly to application supervision tree** (no conditional
   logic)

### **Phase 3: Configuration Setup**

1. **Add Discord configuration** to config files (config.exs, dev.exs,
   runtime.exs)
2. **Set up environment variables** for Discord token
3. **Configure Nostrum** for Discord API access

### **Phase 4: Integration Verification**

1. **Validate consumer module** compilation
2. **Check application startup** with Discord consumer
3. **Verify command registration** capability

## Installer Task Structure

The installer should implement:

```elixir
defmodule Mix.Tasks.AshDiscord.Install do
  use Igniter.Mix.Task

  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :ash,
      schema: [
        domains: :string,
        consumer: :string
      ],
      aliases: [
        d: :domains,
        c: :consumer
      ]
    }
  end

  def igniter(igniter) do
    igniter
    |> add_nostrum_dependency()
    |> generate_discord_consumer()
    |> add_consumer_to_application_with_igniter()
    |> setup_discord_configuration()
  end

  defp add_consumer_to_application_with_igniter(igniter) do
    consumer_module = Module.concat([
      Igniter.Project.Application.app_name(igniter) |> Macro.camelize(),
      "DiscordConsumer"
    ])

    Igniter.Project.Application.add_new_child(igniter, consumer_module)
  end
end
```

This research provides the foundation for implementing a comprehensive
AshDiscord installer that follows established patterns while providing a simple,
direct integration approach.
