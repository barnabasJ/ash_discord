# AshDiscord Igniter Installer - Implementation Breakdown

## Implementation Plan Summary

Transform the strategic implementation plan into a comprehensive Mix task
installer (`mix igniter.install ash_discord`) that automates Discord bot
integration for Phoenix applications using the established AshDiscord.Consumer
pattern.

**Key Objectives:**

- Single command installation with automatic dependency management
- Consumer generation with DSL configuration using `use AshDiscord.Consumer`
- Environment-specific Discord token configuration across dev/test/prod
- Automatic supervision tree integration
- Production-ready configuration with secure token management

## Implementation Instructions

**IMPORTANT**: After completing each numbered step, commit your changes with the
suggested commit message. This ensures clean history and easy rollback if
needed.

**Testing Approach**: Write tests before implementing each task. Use
`Igniter.Test` for component validation and integration testing for end-to-end
workflows.

**Quality Gates**: Each phase must pass compilation, tests, and basic
functionality verification before proceeding to the next phase.

## Implementation Checklist

### Phase 1: Foundation & Core Infrastructure

#### 1. [x] **Create Main Installer Task Structure**

1.1. [x] Create `lib/mix/tasks/ash_discord.install.ex` - Follow pattern from Ash
ecosystem installers - Implement `use Igniter.Mix.Task` behavior - Add proper
module documentation with usage examples - 📖
[Igniter.Mix.Task](https://hexdocs.pm/igniter/Igniter.Mix.Task.html) 1.2. [x]
Implement `info/2` callback with option schema - Add `--consumer` (string),
`--domains` (string), `--yes` (boolean) options - Set appropriate aliases: `-c`,
`-d`, `-y` - Configure task group as `:ash` for ecosystem consistency 1.3. [x]
Create basic `igniter/1` callback structure - Set up pipeline placeholder for
all installation phases - Add app_name extraction:
`Igniter.Project.Application.app_name(igniter)` - Add option parsing and
validation structure

📝 **Commit**:
`feat(installer): add basic Mix.Tasks.AshDiscord.Install structure`

#### 2. [ ] **Add Option Parsing and Validation**

2.1. [ ] Create option parsing function - Extract and validate `--consumer` with
default naming (`AppName.DiscordConsumer`) - Parse `--domains` as
comma-separated list with validation - Handle `--yes` flag for skipping
confirmations 2.2. [ ] Add project compatibility validation - Verify Phoenix
application structure exists - Check for Ash framework presence (dependency or
source) - Validate Phoenix version compatibility (>= 1.7) 2.3. [ ] Implement
domain validation logic - Check specified domains exist in the project -
Validate domains use proper Ash.Domain extensions - Provide clear error messages
for invalid domains

📝 **Commit**:
`feat(installer): add comprehensive option parsing and project validation`

#### 3. [ ] **Add Helper Functions to Installer**

3.1. [ ] Add consumer generation helper functions to installer module

- Add `generate_consumer_module/2` function for template generation
- Include DSL configuration handling for domains
- Add comprehensive module documentation generation logic 3.2. [ ] Add
  configuration management helper functions
- Add `setup_discord_configuration/1` function for environment-specific config
- Handle Nostrum configuration across dev/test/prod
- Include security validation for production tokens 3.3. [ ] Add dependency
  management helper functions
- Add `add_dependencies/1` function for nostrum dependency management
- Handle ash_discord runtime dependency configuration
- Add dependency conflict detection and resolution logic

📝 **Commit**:
`feat(installer): add helper functions for consumer generation, configuration, and dependencies`

### Phase 2: Core Generation & Configuration

#### 4. [ ] **Implement Consumer Module Generation**

4.1. [ ] Implement `generate_consumer_module/2` helper function

- Use existing pattern from `lib/ash_discord/consumer.ex:1-50`
- Generate module with `use AshDiscord.Consumer` and DSL block
- Add comprehensive module documentation with examples
- Follow naming pattern: `#{app_name}.DiscordConsumer` 4.2. [ ] Add domain
  configuration logic to generation function
- Add `domains([...])` configuration based on `--domains` option
- Include commented examples when domains list is empty
- Add guidance comments for manual domain addition 4.3. [ ] Use
  `Igniter.Project.Module.create_module/3` in helper function
- Ensure proper AST generation and formatting
- Handle module conflicts and existing file detection
- Add overwrite confirmation when consumer already exists

📝 **Commit**:
`feat(installer): implement Discord consumer module generation with DSL`

#### 5. [ ] **Add Dependency Management**

5.1. [ ] Implement `add_dependencies/1` helper function

- Use `Igniter.Project.Deps.add_dep/2` to add `{:nostrum, "~> 0.10"}`
- Include version compatibility validation
- Handle existing dependency conflicts gracefully 5.2. [ ] Add ash_discord
  runtime availability check to helper function
- Verify ash_discord is available at runtime, not just dev/test
- Add runtime dependency if needed
- Validate ash_discord version compatibility 5.3. [ ] Add dependency conflict
  resolution to helper function
- Check for existing Discord libraries (nostrum versions)
- Provide clear guidance for resolving conflicts
- Add option to force dependency updates if needed

📝 **Commit**:
`feat(installer): add nostrum and ash_discord dependency management`

#### 6. [ ] **Setup Environment Configuration**

6.1. [ ] Implement `setup_discord_configuration/1` helper function

- Use `Igniter.Project.Config.configure_new/4` for `config/dev.exs`
- Add `config :nostrum, token: "your_dev_bot_token_here"`
- Include configuration comments for token setup 6.2. [ ] Add production
  environment config to helper function
- Configure `config/runtime.exs` with secure token configuration
- Add `System.get_env("DISCORD_TOKEN")` with error handling
- Follow Phoenix runtime configuration patterns 6.3. [ ] Add test environment
  handling to helper function
- Add test-specific Nostrum configuration if needed
- Ensure tests don't require Discord tokens
- Configure appropriate test environment behavior

📝 **Commit**: `feat(installer): add environment-specific Discord configuration`

#### 7. [ ] **Integrate Consumer into Supervision Tree**

7.1. [ ] Use `Igniter.Project.Application.add_new_child/3` for integration - Add
consumer module to application supervision tree - Position after PubSub if
present, otherwise at appropriate location - Follow pattern from
`lib/steward/application.ex:42-43` 7.2. [ ] Add supervision configuration - Use
simple child spec: `{ConsumerModule, []}` - Include restart strategy appropriate
for Discord consumers - Add positioning logic for integration with existing
children 7.3. [ ] Validate supervision tree integration - Ensure consumer starts
properly with application - Handle supervision tree conflicts gracefully - Add
validation for successful integration

📝 **Commit**:
`feat(installer): integrate Discord consumer into application supervision tree`

### Phase 3: Quality & Integration

#### 8. [ ] **Add Spark.Formatter Configuration**

8.1. [ ] Update `.formatter.exs` to include AshDiscord DSL formatting - Add
`import_deps: [:ash_discord]` if not present - Include proper DSL formatting for
`ash_discord_consumer` blocks - Follow existing Spark.Formatter patterns in the
project 8.2. [ ] Validate formatter configuration - Test DSL formatting works
properly on generated consumer - Ensure code formatting follows project
conventions - Add formatter validation to installer process

📝 **Commit**:
`feat(installer): add Spark.Formatter configuration for AshDiscord DSL`

#### 9. [ ] **Generate Comprehensive Documentation**

9.1. [ ] Add detailed module documentation to generated consumer - Include
module overview and usage instructions - Add practical examples for Discord
command setup - Include links to relevant documentation and guides 9.2. [ ]
Generate installation summary and next steps - Provide clear guidance for
Discord bot setup - Include token configuration instructions - Add domain
configuration examples and patterns 9.3. [ ] Add developer workflow
documentation - Include common Discord development patterns - Add
troubleshooting guide for common issues - Provide testing and deployment
guidance

📝 **Commit**:
`feat(installer): add comprehensive documentation and developer guidance`

#### 10. [ ] **Implement Integration Validation**

10.1. [ ] Add compilation validation - Verify generated code compiles without
errors - Check for missing dependencies or imports - Validate DSL configuration
is syntactically correct 10.2. [ ] Add application startup validation - Test
application starts successfully with consumer - Verify consumer appears in
supervision tree - Check Discord connection capability (with valid token) 10.3.
[ ] Add final integration testing - Test complete installation workflow
end-to-end - Verify all configuration is properly set up - Validate installer
can be run multiple times safely (idempotent)

📝 **Commit**:
`feat(installer): add comprehensive integration validation and testing`

### Phase 4: Testing & Quality Assurance

#### 11. [ ] **Create Comprehensive Test Suite**

11.1. [ ] Create `test/mix/tasks/ash_discord_install_test.exs` - Use
`Igniter.Test` for component validation - Test option parsing and validation
logic - Add tests for domain validation and error handling - 📖
[Igniter Testing](https://hexdocs.pm/igniter/testing.html) 11.2. [ ] Add
consumer generation tests - Test consumer module creation with various options -
Validate DSL configuration generation - Test consumer naming and documentation
generation 11.3. [ ] Add configuration and dependency tests - Test
environment-specific configuration setup - Validate dependency management and
version handling - Test supervision tree integration logic 11.4. [ ] Add
end-to-end installation tests

- Test complete installation workflow with different scenarios - Test
  installation with different domain configurations - Validate error handling
  and edge cases
- Test installer idempotency (multiple runs)

📝 **Commit**:
`test(installer): add comprehensive test suite with unit and integration tests`

#### 12. [ ] **Quality Assurance and Final Validation**

12.1. [ ] Run complete test suite and validate coverage - Ensure 95%+ test
coverage target is met - Fix any failing tests or coverage gaps - Validate all
edge cases are properly handled 12.2. [ ] Test installer in real Phoenix
applications - Test with minimal Phoenix application - Test with complex Phoenix
application with multiple domains - Validate Discord connection and command
registration 12.3. [ ] Final documentation and code review - Review all
generated code for quality and consistency - Validate documentation is complete
and accurate - Ensure installer follows Ash ecosystem conventions

📝 **Commit**:
`feat(installer): final quality assurance and validation complete`

## Testing Strategy

### Test-First Development Approach

**Unit Testing**: Each task should begin with writing failing tests, then
implementing functionality to make tests pass.

**Integration Testing**: After completing each phase, run integration tests to
ensure the installer works end-to-end.

**Quality Gates**:

- Phase 1: Basic structure compiles and options parse correctly
- Phase 2: Generated consumer compiles and integrates with application
- Phase 3: Complete installation works in test Phoenix application
- Phase 4: All tests pass with 95%+ coverage

### Test File Organization

```
test/
├── mix/
│   └── tasks/
│       └── ash_discord_install_test.exs      # Comprehensive test suite
└── support/
    └── test_app/                             # Test Phoenix application
```

## Success Criteria

### Phase Completion Requirements

**Phase 1 Complete When:**

- ✅ Mix task loads and parses options correctly
- ✅ Project validation works for Phoenix/Ash applications
- ✅ Domain validation provides clear error messages
- ✅ Supporting installer modules compile successfully

**Phase 2 Complete When:**

- ✅ Consumer generation creates working Discord consumer modules
- ✅ Dependencies install without conflicts
- ✅ Environment configuration is properly set up
- ✅ Supervision tree integration works correctly

**Phase 3 Complete When:**

- ✅ Formatter configuration enables proper DSL formatting
- ✅ Generated documentation is comprehensive and helpful
- ✅ Integration validation ensures complete functionality
- ✅ Application compiles and starts with Discord consumer

**Phase 4 Complete When:**

- ✅ Comprehensive test suite achieves 95%+ coverage
- ✅ All test scenarios validate end-to-end workflows
- ✅ Installer works reliably across different Phoenix setups
- ✅ Quality assurance confirms production readiness

### Final Success Validation

**Installation Success**: `mix igniter.install ash_discord` completes
successfully in test Phoenix application

**Consumer Generation**: Generated Discord consumer compiles and integrates
properly

**Configuration Setup**: Environment-specific configuration works across
dev/test/prod

**Supervision Integration**: Consumer starts with application and appears in
supervision tree

**Documentation Quality**: Generated code includes comprehensive documentation
and examples

**Test Coverage**: Complete test suite with 95%+ coverage and all tests passing

## Implementation Notes

### Key Implementation Files

- **Main Installer**: `lib/mix/tasks/ash_discord.install.ex` (contains all
  helper functions)

### Integration Points

- **Existing Consumer Pattern**: Build upon `lib/ash_discord/consumer.ex:1-50`
- **Steward Application Pattern**: Follow `lib/steward/application.ex:42-43`
- **Igniter Ecosystem Consistency**: Match patterns from other Ash installers

### Documentation Links

- 📖 [Igniter.Mix.Task](https://hexdocs.pm/igniter/Igniter.Mix.Task.html)
- 📖 [Igniter Testing](https://hexdocs.pm/igniter/testing.html)
- 📖
  [AshDiscord Consumer DSL](https://hexdocs.pm/ash_discord/AshDiscord.Consumer.html)
- 📖 [Nostrum Configuration](https://hexdocs.pm/nostrum/Nostrum.html)

This breakdown transforms the strategic implementation plan into actionable,
testable tasks that can be implemented systematically with clear validation
criteria and quality gates at each phase.
