# Strategic Implementation Plan: AshDiscord Igniter Installer

## Impact Analysis Summary

**Primary Change**: Implementation of a comprehensive Mix task installer
(`mix igniter.install ash_discord`) that automates Discord bot integration for
Phoenix applications using the established AshDiscord.Consumer pattern.

**Key Integration Points**:

- **Consumer Generation**: Creates Discord consumer modules with DSL
  configuration using `use AshDiscord.Consumer`
- **Supervision Tree Integration**: Automatic addition to application
  supervision tree using `Igniter.Project.Application.add_new_child`
- **Configuration Management**: Environment-specific Discord token and Nostrum
  configuration across dev/test/prod environments
- **Dependency Coordination**: Manages nostrum ~> 0.10 and ash_discord
  dependencies with version compatibility validation

**Discovered Patterns Applied**:

- **Consumer DSL Pattern**: From
  `/home/joba/sandbox/steward/lib/steward/discord_consumer.ex:15-31` - Uses
  `ash_discord_consumer` blocks with domain configuration
- **Application Integration**: From
  `/home/joba/sandbox/steward/lib/steward/application.ex:42-43` - Direct
  consumer addition to supervision tree
- **Igniter Task Structure**: Following `ash_authentication.install` patterns
  for ecosystem consistency

## Feature Specification

### User Stories and Acceptance Criteria

#### **Story 1: Simple Discord Bot Installation**

**As a Phoenix developer**, I want to install Discord bot functionality with a
single command so that I can integrate Discord interactions with my existing Ash
domains.

**Acceptance Criteria**:

- ✅ Single command installation: `mix igniter.install ash_discord`
- ✅ Automatic dependency installation (nostrum, ash_discord)
- ✅ Consumer module generation with appropriate naming
  (`AppName.DiscordConsumer`)
- ✅ Automatic supervision tree integration
- ✅ Environment-specific configuration setup
- ✅ Application compiles and starts successfully after installation

#### **Story 2: Domain-Aware Command Registration**

**As a developer with existing Ash domains**, I want to explicitly specify which
domains should handle Discord interactions so that I have control over what is
exposed to Discord.

**Acceptance Criteria**:

- ✅ Installer allows explicit domain specification via --domains flag
- ✅ Generated consumer includes only specified domains in DSL block
- ✅ Consumer compiles with proper domain references when domains specified
- ✅ Consumer generates with empty domains list when none specified
- ✅ Clear guidance provided on how to add domains manually

#### **Story 3: Production-Ready Configuration**

**As a developer deploying to production**, I want secure, environment-specific
Discord configuration so that my bot works reliably across development, test,
and production environments.

**Acceptance Criteria**:

- ✅ Environment variables properly configured for Discord token
- ✅ Dev environment uses placeholder token
- ✅ Test environment uses test configuration
- ✅ Production environment requires secure token validation
- ✅ Configuration follows Phoenix conventions

### API Contracts and Data Flow

#### **Mix Task Interface**

```elixir
# Command Interface
mix igniter.install ash_discord [options]

# Options Schema
--consumer, -c    # Consumer module name (default: AppName.DiscordConsumer)
--domains, -d     # Comma-separated domain list (default: empty, user must specify)
--yes, -y         # Skip confirmation prompts
```

#### **Generated Consumer Interface**

```elixir
defmodule AppName.DiscordConsumer do
  use AshDiscord.Consumer

  ash_discord_consumer do
    # Specify domains that should handle Discord interactions
    # domains([App.Discord, App.Chat])
    domains([])
  end
end
```

#### **Configuration Data Flow**

```
Environment Variables → Config Files → Nostrum → Discord API
DISCORD_TOKEN → config/runtime.exs → :nostrum config → WebSocket connection
```

### State Management Requirements

#### **Installation State**

- **Dependency Resolution**: Track nostrum and ash_discord installation status
- **File Generation**: Track consumer module creation and modification status
- **Configuration State**: Track config file updates across environments
- **Supervision Integration**: Track application.ex modification status

#### **Runtime State Management**

- **Discord Connection**: Consumer manages WebSocket connection state through
  Nostrum
- **Command Registration**: Automatic registration on guild_create and ready
  events
- **Event Processing**: Stateless event handling with Ash domain delegation

### Integration Points with Existing Systems

#### **Ash Framework Integration**

- **Explicit Domain Specification**: Developer control over which domains handle
  Discord interactions
- **Resource Mapping**: Consumer DSL allows mapping Discord entities to Ash
  resources
- **Action Invocation**: Discord commands automatically invoke corresponding Ash
  actions

#### **Phoenix Framework Integration**

- **Supervision Tree**: Consumer added to application supervision tree
  automatically
- **Configuration Management**: Follows Phoenix config conventions across
  environments
- **Development Workflow**: Compatible with Phoenix development patterns

#### **OTP Integration**

- **Supervision Strategy**: Consumer supervised with restart strategies
- **Process Management**: Discord gateway connection managed through Nostrum
  processes
- **Error Handling**: OTP supervision handles connection failures and restarts

## Technical Design

### Data Models and Schema Changes

#### **No Database Schema Changes Required**

The installer creates code and configuration only - no database migrations
needed.

#### **Generated Module Structure**

```elixir
# lib/app_name/discord_consumer.ex
defmodule AppName.DiscordConsumer do
  @moduledoc """
  Discord consumer for handling Discord events and commands.

  This consumer automatically processes Discord interactions and routes them
  to the appropriate Ash actions based on your domain configuration.
  """

  use AshDiscord.Consumer

  ash_discord_consumer do
    # Add your Ash domains that should handle Discord interactions
    # Example: domains([AppName.Discord, AppName.Chat])
    domains([])
  end

  # Override callbacks as needed:
  # @impl true
  # def handle_message_create(message), do: super(message)
end
```

### Integration Details Using Existing Patterns

#### **Consumer Generation Pattern** (from steward/discord_consumer.ex)

- **Base Pattern**: `use AshDiscord.Consumer` with DSL configuration block
- **Configuration Structure**: `ash_discord_consumer do ... end` block with
  domains specification
- **Domain Integration**: Automatic command registration based on domain
  configuration

#### **Supervision Tree Integration** (from steward/application.ex)

- **Direct Addition**: Consumer inserted directly into children list
- **Positioning Strategy**: Added after PubSub but before Phoenix.Endpoint
- **No Conditional Logic**: Always included when installed (simple, reliable
  pattern)

#### **Configuration Pattern** (following Phoenix conventions)

```elixir
# config/config.exs - Base configuration
# no config needed

# config/dev.exs - Development placeholder
config :nostrum,
  token: "your_dev_bot_token_here"

# config/test.exs - Test configuration
# no need for configuration, set runtime: Mix.env() != :test
# in mix.exs to not start Nostrum in test env

# config/runtime.exs - Production security
config :nostrum,
  token: System.get_env("DISCORD_TOKEN") ||
    raise "Missing environment variable `DISCORD_TOKEN`!"
```

### Module Organization Following Architecture Guidance

#### **Primary Installer Module**

**File**: `lib/mix/tasks/ash_discord.install.ex`

```elixir
defmodule Mix.Tasks.AshDiscord.Install do
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :ash,
      schema: [consumer: :string, domains: :string, yes: :boolean],
      aliases: [c: :consumer, d: :domains, y: :yes]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> add_nostrum_dependency()
    |> ensure_ash_discord_runtime()
    |> generate_discord_consumer()
    |> add_consumer_to_supervision_tree()
    |> setup_discord_configuration()
    |> add_formatter_configuration()
  end
end
```

#### **Supporting Modules** (following architecture recommendations)

- **Consumer Template Generator**: Handles DSL-based module generation
- **Configuration Manager**: Manages environment-specific config setup
- **Dependency Coordinator**: Handles version compatibility and dependency
  management

## Third-Party Integrations

### Discord API Integration via Nostrum

#### **Authentication and Connection Management**

- **Bot Token**: Secure token management through environment variables
- **WebSocket Gateway**: Nostrum handles Discord gateway connection
  automatically
- **Rate Limiting**: Built-in rate limiting through Nostrum library

#### **Event Processing Pipeline**

```
Discord Event → Nostrum → AshDiscord.Consumer → Ash Domain → Response
```

#### **Command Registration Flow**

```
Bot Ready → Discover Domains → Extract Commands → Register with Discord → Handle Interactions
```

#### **Security Configuration**

- **Token Storage**: Environment-specific secure token management
- **Permission Scoping**: Bot permissions configured through Discord Developer
  Portal
- **Interaction Verification**: Automatic signature verification through Nostrum

## Implementation Strategy

### Primary Approach: Consumer-DSL-Based Installation

**Philosophy**: Generate complete, working Discord integration with minimal
manual configuration required.

**Key Principles**:

1. **Convention over Configuration**: Sensible defaults for consumer naming and
   domain discovery
2. **Environment Awareness**: Proper configuration for dev/test/prod
   environments
3. **Ecosystem Consistency**: Follow established Ash/Igniter patterns
4. **Production Readiness**: Secure configuration and proper supervision
   integration

### Agent Consultations Summary

#### **Architecture Agent Guidance Applied**

- **Modular Structure**: Separate concerns between installer phases and consumer
  configuration
- **Template-Based Generation**: Use structured templates for consumer modules
  with DSL configuration
- **Integration Strategy**: Leverage `Igniter.Project.Application.add_new_child`
  for supervision tree modification
- **Testing Architecture**: Comprehensive integration testing framework for
  installer validation

#### **Elixir Expert Patterns Applied**

- **Igniter.Mix.Task Implementation**: Proper `info/2` and `igniter/1` callback
  implementation
- **Consumer DSL Configuration**: Generate modules with
  `use AshDiscord.Consumer` and `ash_discord_consumer` DSL block
- **Pipe Operator Usage**: Appropriate igniter pipeline with multiple operations
- **Configuration Management**: Environment-specific configuration following
  Phoenix patterns

#### **Senior Engineer Strategic Validation**

- **Scalability Assessment**: Current approach suitable for 1-10 guilds,
  requires monitoring for larger scale
- **Configuration Complexity Management**: Implement configuration presets and
  validation framework
- **Testing Strategy**: Comprehensive installer testing framework with
  end-to-end validation
- **Technical Debt Mitigation**: Phase separation and dependency version
  compatibility validation

## Implementation Phases

### Phase 1: Core Installer Infrastructure

**Objective**: Establish the fundamental Mix task and Igniter integration

**Key Components**:

- **Mix.Tasks.AshDiscord.Install**: Main installer task with proper
  Igniter.Mix.Task behavior
- **Option Parsing**: Handle consumer naming, domain specification, and
  confirmation flags
- **Domain Validation**: Validate specified domains exist and use appropriate
  extensions
- **Installation Guidance**: Provide clear instructions for domain configuration

**Success Criteria**:

- ✅ Mix task loads and parses options correctly
- ✅ Validates specified domains exist and are properly configured
- ✅ Handles edge cases (invalid domains, name conflicts, empty domain list)

**Code Pattern Example**:

```elixir
def igniter(igniter) do
  app_name = Igniter.Project.Application.app_name(igniter)
  options = parse_and_validate_options(igniter, app_name)

  igniter
  |> validate_specified_domains(options[:domains])
  |> proceed_with_installation(options)
end
```

### Phase 2: Consumer Generation and Code Management

**Objective**: Generate working Discord consumer modules with proper DSL
configuration

**Key Components**:

- **Consumer Template System**: Generate modules using `use AshDiscord.Consumer`
  pattern
- **DSL Configuration Block**: Create `ash_discord_consumer` blocks with domain
  references
- **Module Documentation**: Generate comprehensive docstrings and usage examples
- **Code Formatting**: Integrate with Spark.Formatter for proper DSL formatting

**Success Criteria**:

- ✅ Generated consumer modules compile successfully
- ✅ DSL configuration properly references specified domains or provides clear
  guidance
- ✅ Generated code follows Elixir style guidelines
- ✅ Documentation includes practical usage examples

**Code Pattern Example**:

```elixir
defp generate_discord_consumer(igniter, options) do
  consumer_content = quote do
    defmodule unquote(options[:consumer]) do
      use AshDiscord.Consumer

      ash_discord_consumer do
        # Add your Ash domains that should handle Discord interactions
        # Example: domains([MyApp.Discord, MyApp.Chat])
        domains(unquote(options[:domains] || []))
      end
    end
  end

  Igniter.Project.Module.create_module(igniter, options[:consumer], consumer_content)
end
```

### Phase 3: Dependency and Configuration Management

**Objective**: Establish proper dependency management and environment-specific
configuration

**Key Components**:

- **Nostrum Dependency**: Add nostrum ~> 0.10 to target application dependencies
- **AshDiscord Runtime**: Ensure ash_discord is available at runtime, not just
  dev/test
- **Environment Configuration**: Set up Discord token configuration across all
  environments
- **Security Validation**: Ensure production configuration requires secure token
  management

**Success Criteria**:

- ✅ Dependencies added without version conflicts
- ✅ All environments have appropriate Discord configuration
- ✅ Production configuration enforces secure token management
- ✅ Development workflow supports easy bot testing

**Code Pattern Example**:

```elixir
defp setup_discord_configuration(igniter) do
  igniter
  |> Igniter.Project.Config.configure("config.exs", :nostrum, [:token], {:system, "DISCORD_TOKEN"})
  |> Igniter.Project.Config.configure_new("dev.exs", :nostrum, [:token], "your_dev_bot_token_here")
  |> Igniter.Project.Config.configure_runtime_env(:prod, :nostrum, [:token], secure_token_config())
end
```

### Phase 4: Integration Verification and Quality Assurance

**Objective**: Verify complete installation works end-to-end with comprehensive
validation

**Key Components**:

- **Supervision Tree Verification**: Confirm consumer properly added to
  application supervision
- **Compilation Validation**: Ensure generated code compiles without errors
- **Application Startup**: Verify application starts successfully with Discord
  consumer
- **Integration Testing**: Test Discord connection and command registration
  capabilities

**Success Criteria**:

- ✅ Application compiles and starts successfully
- ✅ Discord consumer appears in supervision tree
- ✅ Bot can connect to Discord (with valid token)
- ✅ Commands register automatically based on domain configuration

**Code Pattern Example**:

```elixir
defp add_consumer_to_supervision_tree(igniter, options) do
  consumer_module = options[:consumer]

  Igniter.Project.Application.add_new_child(
    igniter,
    consumer_module,
    after: fn child_specs ->
      # Add after PubSub if present, otherwise at end
      Enum.any?(child_specs, &match?({Phoenix.PubSub, _}, &1))
    end
  )
end
```

## Quality and Testing Strategy

### Installer Testing Framework

#### **Unit Testing**: Individual component validation

```elixir
defmodule Mix.Tasks.AshDiscordInstallTest do
  use ExUnit.Case
  import Igniter.Test

  @moduletag :igniter

  test "generates consumer with specified domains" do
    test_project()
    |> Igniter.compose_task("ash_discord.install", ["--domains", "TestApp.Accounts"])
    |> assert_creates("lib/test_app/discord_consumer.ex", """
    defmodule TestApp.DiscordConsumer do
      @moduledoc \"\"\"
      Discord consumer for handling Discord events and commands.

      This consumer automatically processes Discord interactions and routes them
      to the appropriate Ash actions based on your domain configuration.
      \"\"\"

      use AshDiscord.Consumer

      ash_discord_consumer do
        # Add your Ash domains that should handle Discord interactions
        # Example: domains([TestApp.Discord, TestApp.Chat])
        domains([TestApp.Accounts])
      end
    end
    """)
  end

  test "generates consumer with empty domains when none specified" do
    test_project()
    |> Igniter.compose_task("ash_discord.install", [])
    |> assert_creates("lib/test_app/discord_consumer.ex", """
    defmodule TestApp.DiscordConsumer do
      @moduledoc \"\"\"
      Discord consumer for handling Discord events and commands.

      This consumer automatically processes Discord interactions and routes them
      to the appropriate Ash actions based on your domain configuration.
      \"\"\"

      use AshDiscord.Consumer

      ash_discord_consumer do
        # Add your Ash domains that should handle Discord interactions
        # Example: domains([TestApp.Discord, TestApp.Chat])
        domains([])
      end
    end
    """)
  end

  test "adds consumer to supervision tree" do
    test_project()
    |> Igniter.compose_task("ash_discord.install", [])
    |> assert_has_patch("lib/test_app/application.ex", """
    8  |     {TestApp.DiscordConsumer, []}
    """)
  end

  test "creates development configuration" do
    test_project()
    |> Igniter.compose_task("ash_discord.install", [])
    |> assert_creates("config/dev.exs", """
    config :nostrum,
      token: "your_dev_bot_token_here"
    """)
  end
end
```

#### **Integration Testing**: End-to-end installer validation

```elixir
test "installer creates functional Discord integration" do
  test_project()
  |> Igniter.Project.Deps.add_dep({:ash, ">= 3.0.0"})
  |> Igniter.compose_task("ash.gen.domain", ["TestApp.Accounts"])
  |> Igniter.compose_task("ash_discord.install", [])
  |> assert_creates("lib/test_app/discord_consumer.ex")
  |> assert_has_patch("lib/test_app/application.ex")
end
```

### Quality Validation Testing Using Discovered Patterns

#### **AshDiscord Consumer Testing** (following existing patterns)

- **Mock Discord API**: Use Mimic for mocking Nostrum.Api calls in tests
- **Event Simulation**: Test consumer callbacks with simulated Discord events
- **Command Testing**: Verify slash command registration and handling

#### **Configuration Testing** (following Phoenix patterns)

- **Environment Validation**: Test configuration setup across dev/test/prod
  environments
- **Token Security**: Verify production configuration properly requires secure
  tokens
- **Nostrum Integration**: Test Discord connection with proper configuration

## Success Criteria

### Installation Success Metrics

#### **Primary Success Criteria**

1. ✅ **Single Command Installation**: `mix igniter.install ash_discord`
   completes successfully
2. ✅ **Automatic Dependency Resolution**: nostrum and ash_discord dependencies
   added without conflicts
3. ✅ **Consumer Generation**: Discord consumer module created with proper DSL
   configuration
4. ✅ **Supervision Integration**: Consumer automatically added to application
   supervision tree
5. ✅ **Configuration Setup**: Environment-specific Discord configuration
   created across dev/test/prod
6. ✅ **Application Startup**: Application compiles and starts successfully
   after installation

#### **Integration Success Criteria**

1. ✅ **Explicit Domain Control**: Installer allows explicit domain
   specification with clear guidance for configuration
2. ✅ **Command Registration**: Discord commands register automatically when bot
   connects
3. ✅ **Event Processing**: Discord events properly route to Ash domain actions
4. ✅ **Development Workflow**: Developer can immediately start building Discord
   interactions
5. ✅ **Production Readiness**: Secure configuration enforces proper token
   management

#### **Quality Success Criteria**

1. ✅ **Code Quality**: Generated code follows Elixir style guidelines and best
   practices
2. ✅ **Documentation**: Generated modules include comprehensive documentation
   and examples
3. ✅ **Error Handling**: Installer provides clear error messages for edge cases
4. ✅ **Testing**: Comprehensive test suite validates installer behavior
5. ✅ **Ecosystem Consistency**: Installation process follows established
   Ash/Igniter patterns

### Measurable Outcomes

#### **Developer Experience Metrics**

- **Installation Time**: Complete installation in under 30 seconds
- **Configuration Steps**: Zero manual configuration steps required for basic
  setup
- **Time to First Discord Command**: Developer can create working Discord
  command within 5 minutes
- **Error Rate**: Less than 5% installation failure rate across different
  Phoenix application configurations

#### **Technical Integration Metrics**

- **Dependency Compatibility**: 100% compatibility with supported Ash/Phoenix
  version ranges
- **Application Startup Time**: No more than 10% increase in application startup
  time
- **Memory Usage**: Discord integration adds less than 50MB baseline memory
  usage
- **Test Coverage**: 95%+ test coverage for installer components

### Acceptance Criteria

#### **Functional Requirements**

- ✅ Installer works with Phoenix applications using Ash 3.0+
- ✅ Generated consumer successfully connects to Discord with valid token
- ✅ Slash commands register automatically based on domain configuration
- ✅ Discord events properly trigger Ash domain actions
- ✅ Installation is reversible (consumer can be safely removed)

#### **Non-Functional Requirements**

- ✅ Installation process is idempotent (can be run multiple times safely)
- ✅ Generated code is production-ready with proper supervision and error
  handling
- ✅ Security best practices enforced for token management and environment
  configuration
- ✅ Documentation provides clear guidance for Discord bot setup and deployment
- ✅ Installation follows semantic versioning for compatibility guarantees

This comprehensive implementation plan provides a strategic foundation for
building a robust, maintainable AshDiscord installer that follows established
ecosystem patterns while enabling seamless Discord integration for Phoenix
applications. The plan incorporates architectural guidance, Elixir best
practices, and strategic validation to ensure long-term success and developer
satisfaction.
