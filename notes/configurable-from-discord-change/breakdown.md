# Implementation Task Breakdown: AshDiscord FromDiscord Change System

**Topic:** Create configurable from_discord change implementation breakdown
**Date:** 2025-09-20 **Status:** Breakdown Phase Complete

---

## Implementation Plan Summary

Transform the strategic plan from
`notes/configurable-from-discord-change/plan.md` into a detailed, executable
task breakdown for implementing the single configurable
`AshDiscord.Changes.FromDiscord` module with type-based dispatch.

**Key Strategic Decisions:**

- Single change module with type dispatch (no separate sub-modules for entity
  groups)
- All transformation functions directly in main module (`transform_user/2`,
  `transform_guild/2`, etc.)
- Only utility modules: `Transformations` (shared utilities) and `ApiFetchers`
  (API fallback)
- Testing using existing Discord generators plus new generators for missing
  entities
- 3-phase implementation: Core module + primary entities, remaining entities +
  API fetching, integration + final testing

**Expert Consultations Completed:**

- **test-developer**: TDD/BDD methodology integration with comprehensive testing
  strategy
- **architecture-agent**: Task organization and structural validation within
  existing AshDiscord patterns
- **elixir-expert**: Elixir-specific patterns and implementation guidance
  following proven steward patterns

---

## Implementation Instructions

**IMPORTANT**: After completing each numbered step, commit your changes with the
suggested commit message. This ensures clean history and easy rollback if
needed.

**TDD Requirements**: Write failing tests first for each transformation function
before implementation. Use `@tag :focus` to isolate development of individual
functions.

**Quality Gates**: Each phase must pass comprehensive testing before proceeding
to the next phase.

---

## Implementation Checklist

### Phase 1: Core Module and Primary Entities (Week 1)

#### 1. [x] **Create Main Change Module Foundation** [3 hours]

1.1. [x] Create main module file `lib/ash_discord/changes/from_discord.ex`

- Follow pattern from `lib/ash_discord/consumer.ex:1-50` for module structure
- Implement `use Ash.Resource.Change` behavior
- Add supported types list and validation in `init/1` function
- 📖 [Ash Resource Change DSL](https://hexdocs.pm/ash/Ash.Resource.Change.html)

  1.2. [x] Implement type dispatch mechanism with pattern matching

- Add `@supported_types` module attribute for all 15 Discord entity types
- Create `transform_entity/3` function with pattern matching on type
- Add comprehensive error handling for unsupported types
- Pattern: Follow elixir-expert guidance for robust type dispatch

  1.3. [x] Add struct-first data flow pattern

- Implement `get_discord_data/2` function following steward patterns
- Primary: Check for `:discord_struct` argument
- Secondary: Fallback to API fetch (placeholder for now)
- Error handling for invalid struct formats

  1.4. [x] Create comprehensive test file structure

- Create `test/ash_discord/changes/from_discord_test.exs`
- Import existing Discord generators:
  `import AshDiscord.Test.Generators.Discord`
- Set up test structure for all 15 entity types
- Add test helper functions for changeset creation

📝 **Commit**:
`feat(changes): add configurable FromDiscord change module with type dispatch`

#### 2. [x] **Create Shared Transformations Utility Module** [2 hours]

2.1. [x] Create `lib/ash_discord/changes/from_discord/transformations.ex`

- Follow pattern from existing modules in `lib/ash_discord/` for organization
- Add module documentation following steward patterns
- 📖 [Ash Changeset Functions](https://hexdocs.pm/ash/Ash.Changeset.html)

  2.2. [x] Implement shared datetime transformation utilities

- Add `set_datetime_field/3` function with graceful error handling
- Pattern: Handle nil, empty string, and invalid datetime formats gracefully
- Follow steward pattern for DateTime.from_iso8601/1 with error tolerance

  2.3. [x] Implement Discord email generation utility

- Add `generate_discord_email/2` function
- Pattern: `"discord+#{discord_id}@#{domain}"` format from steward research
- Default domain: `"discord.local"`

  2.4. [x] Implement relationship management utilities

- Add `manage_guild_relationship/2`, `manage_user_relationship/2`,
  `manage_channel_relationship/2`
- Use Ash relationship management with auto-creation:
  `on_no_match: {:create, :from_discord}`
- Pattern:
  `type: :append_and_remove, use_identities: [:discord_id], value_is_key: :discord_id`

  2.5. [x] Create comprehensive test file for transformations - SKIPPED

**DECISION: Skip unit tests, use integration tests only**

- User decided to test only through from_discord actions on test app resources
- Eliminates duplicate test resources and focuses on real-world usage
- Maintains coverage through integration testing patterns

📝 **Commit**:
`feat(transformations): add shared transformation utilities with datetime and relationship handling`

#### 3. [x] **Implement Primary Entity Transformations** [4 hours]

3.1. [x] Implement User entity transformation

- Add `transform_user/2` function in main module
- Follow exact pattern from `test/support/test_app/discord/user.ex:45-65`
- Transform: `:discord_id`, `:discord_username`, `:discord_avatar`, `:email`
- Use `Transformations.generate_discord_email/1` for email field

  3.2. [x] Write comprehensive User transformation tests - SKIPPED

**DECISION: Skip unit tests, use integration tests only**

- Testing through TestApp.Discord.User.from_discord action instead
- Eliminates duplicate test resources and focuses on real-world usage

  3.3. [x] Implement Guild entity transformation

- Add `transform_guild/2` function in main module
- Follow exact pattern from `test/support/test_app/discord/guild.ex:45-65`
- Transform: `:discord_id`, `:name`, `:description`, `:icon`, `:owner_id`
- Handle optional owner_id with nil safety

  3.4. [x] Write comprehensive Guild transformation tests - SKIPPED

**DECISION: Skip unit tests, use integration tests only**

- Testing through TestApp.Discord.Guild.from_discord action instead
- Eliminates duplicate test resources and focuses on real-world usage

  3.5. [x] Implement Role entity transformation

- Add `transform_role/2` function in main module
- Transform: `:discord_id`, `:name`, `:color`, `:permissions`
- Convert permissions to string: `to_string(discord_data.permissions)`
- Use `Transformations.manage_guild_relationship/2` for guild association

  3.6. [x] Write comprehensive Role transformation tests - SKIPPED

**DECISION: Skip unit tests, use integration tests only**

- Testing through TestApp.Discord.Role.from_discord action instead
- Eliminates duplicate test resources and focuses on real-world usage

  3.7. [x] Implement Emoji entity transformation

- Add `transform_emoji/2` function in main module
- Transform: `:discord_id`, `:name`, `:animated` (default false)
- Use `Transformations.manage_guild_relationship/2` for guild association
- Handle boolean field defaults properly

  3.8. [x] Write comprehensive Emoji transformation tests - SKIPPED

**DECISION: Skip unit tests, use integration tests only**

- Testing through TestApp.Discord.Emoji.from_discord action instead
- Eliminates duplicate test resources and focuses on real-world usage

📝 **Commit**:
`feat(entities): implement User, Guild, Role, and Emoji transformations with comprehensive tests`

#### 4. [ ] **Integration Testing and Phase 1 Validation** [2 hours]

4.1. [ ] Create integration tests with existing test resources

- Test `TestApp.Discord.User.from_discord/1` with new change module
- Verify compatibility with existing resource patterns
- Test upsert behavior with identity matching

  4.2. [ ] Add missing Discord generators for comprehensive testing

- Extend `test/support/generators/discord.ex` with missing generators
- Add `permission_overwrite/1`, `voice_state/1`, `message_attachment/1`
  generators
- Follow patterns from existing generators for consistency
- 📖 [ExUnit Testing Guide](https://hexdocs.pm/ex_unit/ExUnit.html)

  4.3. [ ] Run comprehensive test suite validation

- All primary entity tests passing
- Integration tests with existing resources working
- No regressions in existing functionality

  4.4. [ ] Validate Phase 1 success criteria

- [ ] Main change module with type dispatch working
- [ ] Primary entities (User, Guild, Role, Emoji) implemented and tested
- [ ] Shared transformation utilities created and tested
- [ ] Integration with existing test resources validated

📝 **Commit**:
`feat(integration): add integration tests and missing Discord generators for Phase 1 validation`

### Phase 2: Complex and Remaining Entities (Week 2)

#### 5. [ ] **Implement Complex Entity Transformations** [5 hours]

5.1. [ ] Implement GuildMember entity transformation with datetime parsing

- Add `transform_guild_member/2` function in main module
- Follow exact pattern from
  `test/support/test_app/discord/guild_member.ex:45-75`
- Transform: `:guild_id`, `:user_id`, `:nick`, `:roles`, boolean fields
- Use `Transformations.set_datetime_field/3` for `:joined_at`, `:premium_since`
- Use relationship management for guild and user associations

  5.2. [ ] Write comprehensive GuildMember transformation tests

- Test datetime parsing with valid ISO8601 strings
- Test graceful handling of invalid datetime formats
- Test nil datetime handling
- Test boolean field defaults (deaf, mute, pending)
- Test guild and user relationship management

  5.3. [ ] Implement Channel entity transformation with permission overwrites

- Add `transform_channel/2` function in main module
- Transform: `:discord_id`, `:name`, `:type`, `:position`, `:topic`, `:nsfw`,
  `:parent_id`
- Add permission overwrites transformation utility in Transformations module
- Use `Transformations.manage_guild_relationship/2` for guild association

  5.4. [ ] Add permission overwrites transformation utility

- Add `transform_permission_overwrites/1` to Transformations module
- Convert overwrites to map format:
  `%{"id" => id, "type" => type, "allow" => allow, "deny" => deny}`
- Handle nil and empty list cases gracefully
- Convert numeric values to strings for consistency

  5.5. [ ] Write comprehensive Channel transformation tests

- Test with channel generator including permission_overwrites
- Test permission overwrites transformation with various formats
- Test nil and empty permission overwrites handling
- Test guild relationship management
- Test all attribute transformations

  5.6. [ ] Implement Message entity transformation

- Add `transform_message/2` function in main module
- Transform: `:discord_id`, `:content`, `:author_id`, `:channel_id`,
  `:timestamp`
- Use `Transformations.manage_channel_relationship/2` for channel association
- Handle message attachments relationship

  5.7. [ ] Write comprehensive Message transformation tests

- Test with message generator including attachments
- Test channel relationship management
- Test attachment handling (if present)
- Test all attribute transformations

📝 **Commit**:
`feat(complex-entities): implement GuildMember, Channel, and Message transformations with datetime and permission handling`

#### 6. [ ] **Implement Remaining Entity Transformations** [4 hours]

6.1. [ ] Implement VoiceState entity transformation

- Add `transform_voice_state/2` function in main module
- Transform: `:user_id`, `:channel_id`, `:session_id`, boolean fields
- Use `Transformations.set_datetime_field/3` for `:request_to_speak_timestamp`
- Handle all boolean fields with defaults

  6.2. [ ] Implement Webhook entity transformation

- Add `transform_webhook/2` function in main module
- Transform: `:discord_id`, `:name`, `:avatar`, `:channel_id`, `:token`
- Use `Transformations.manage_channel_relationship/2` for channel association

  6.3. [ ] Implement Invite entity transformation

- Add `transform_invite/2` function in main module
- Transform: `:code`, `:guild_id`, `:channel_id`, `:inviter_id`, `:uses`,
  `:max_uses`
- Use `Transformations.set_datetime_field/3` for datetime fields
- Use relationship management for guild and channel associations

  6.4. [ ] Implement Message-related entity transformations

- Add `transform_message_attachment/2`, `transform_message_reaction/2` functions
- Follow steward patterns for attachment and reaction handling
- Use appropriate relationship management

  6.5. [ ] Implement remaining entity transformations

- Add `transform_typing_indicator/2`, `transform_sticker/2`,
  `transform_interaction/2`
- Follow steward patterns for each entity type
- Use appropriate relationship management and transformations

  6.6. [ ] Write comprehensive tests for all remaining entities

- Create tests for each entity type using appropriate generators
- Test all transformation patterns and edge cases
- Verify relationship management works correctly
- Test error handling scenarios

📝 **Commit**:
`feat(remaining-entities): implement VoiceState, Webhook, Invite, and message-related entity transformations`

#### 7. [ ] **Create API Fetchers Module** [2 hours]

7.1. [ ] Create `lib/ash_discord/changes/from_discord/api_fetchers.ex`

- Add module documentation for API fallback functionality
- Implement `fetch_from_api/2` function with entity type dispatch
- Add Discord ID extraction from changeset attributes

  7.2. [ ] Implement API fetch placeholder functionality

- Add logging for API fetch attempts
- Return informative error encouraging struct-first pattern
- Prepare structure for future Nostrum API integration

  7.3. [ ] Create comprehensive test file for API fetchers

- Create `test/ash_discord/changes/from_discord/api_fetchers_test.exs`
- Test Discord ID extraction from changeset
- Test error handling for missing Discord ID
- Test logging functionality

  7.4. [ ] Update main module to use API fetchers

- Integrate `ApiFetchers.fetch_from_api/2` in `get_discord_data/2`
- Test fallback behavior when no discord_struct provided
- Verify graceful error handling

📝 **Commit**:
`feat(api-fetchers): add API fallback module with comprehensive error handling and logging`

#### 8. [ ] **Phase 2 Validation and Testing** [1 hour]

8.1. [ ] Run comprehensive test suite for all 15 entity types

- All entity transformations working correctly
- All shared utilities functioning properly
- API fetcher module working as expected
- No regressions from Phase 1 functionality

  8.2. [ ] Validate Phase 2 success criteria

- [ ] All 15 Discord entity types from steward research supported
- [ ] Complex transformations (permission overwrites, datetime parsing) working
      correctly
- [ ] API fallback functionality tested and working

📝 **Commit**:
`test(validation): validate all entity types and Phase 2 completion`

### Phase 3: Integration and Final Testing (Week 3)

#### 9. [ ] **Update Existing Test Resources** [3 hours]

9.1. [ ] Update User test resource to use new change module

- Modify `test/support/test_app/discord/user.ex` action
- Replace inline change with
  `change {AshDiscord.Changes.FromDiscord, type: :user}`
- Verify all existing tests still pass

  9.2. [ ] Update Guild test resource to use new change module

- Modify `test/support/test_app/discord/guild.ex` action
- Replace inline change with
  `change {AshDiscord.Changes.FromDiscord, type: :guild}`
- Verify all existing tests still pass

  9.3. [ ] Update GuildMember test resource to use new change module

- Modify `test/support/test_app/discord/guild_member.ex` action
- Replace inline change with
  `change {AshDiscord.Changes.FromDiscord, type: :guild_member}`
- Verify all existing tests still pass

  9.4. [ ] Run full test suite validation

- All existing tests pass with new change module
- No regressions in functionality

📝 **Commit**:
`refactor(test-resources): update all test resources to use configurable FromDiscord change module`

#### 10. [ ] **Final Integration and Quality Assurance** [2 hours]

10.1. [ ] Run complete test suite across all phases

- All transformation tests passing
- All integration tests passing
- All utility module tests passing

  10.2. [ ] Validate final success criteria

- [ ] All existing test resources successfully use new change module
- [ ] All 15 Discord entity types working correctly
- [ ] No regressions in existing functionality

  10.3. [ ] Prepare for production deployment

- Final code review and cleanup
- Integration testing with real Discord data

📝 **Commit**:
`feat(complete): finalize configurable FromDiscord change system implementation`

---

## TDD/BDD Integration Plan

### Test-First Development Requirements

**Every transformation function must be implemented with this TDD cycle:**

1. **Red**: Write failing test that describes expected behavior
2. **Green**: Implement minimal code to make test pass
3. **Refactor**: Clean up implementation while keeping tests green
4. **Validate**: Ensure integration with existing patterns works

### Behavior Specifications

**User Entity Transformation:**

- **Given** a Discord user struct with username and avatar
- **When** transforming using type :user
- **Then** all user attributes are properly mapped and email is generated

**GuildMember Entity Transformation:**

- **Given** a Discord guild member struct with datetime fields
- **When** transforming using type :guild_member
- **Then** datetime fields are parsed correctly and relationships are managed

**Channel Entity Transformation:**

- **Given** a Discord channel struct with permission overwrites
- **When** transforming using type :channel
- **Then** permission overwrites are transformed to proper format and guild
  relationship is managed

### Quality Gates

**Phase 1 Quality Gate:**

- All primary entity tests passing (User, Guild, Role, Emoji)
- Shared utilities fully tested and working
- Integration tests with existing resources passing

**Phase 2 Quality Gate:**

- All 15 Discord entity types supported and tested
- Complex transformations (datetime, permissions) working correctly
- API fallback functionality implemented and tested

**Phase 3 Quality Gate:**

- All existing test resources updated and working
- All 15 Discord entity types implemented and tested
- Final integration validation complete

---

## Task Specifications

### File References and Patterns

**Main Module Implementation:**

- Follow pattern from `lib/ash_discord/consumer.ex:1-50` for module structure
- Use exact transformation patterns from
  `test/support/test_app/discord/*.ex:45-65`
- Reference `lib/ash_discord/` modules for organization conventions

**Testing Patterns:**

- Use generators from `test/support/generators/discord.ex`
- Follow test structure from `test/ash_discord/consumer_test.exs`
- Reference integration patterns from existing resource tests

**Documentation Links:**

- 📖 [Ash Resource Change DSL](https://hexdocs.pm/ash/Ash.Resource.Change.html)
- 📖 [Ash Changeset Functions](https://hexdocs.pm/ash/Ash.Changeset.html)
- 📖 [ExUnit Testing Guide](https://hexdocs.pm/ex_unit/ExUnit.html)
- 📖
  [Writing Great Documentation](https://jacobian.org/series/great-documentation/)

### Implementation Guidelines

**Code Organization:**

- All 15 transformation functions directly in main module for simplicity
- Utility modules only for shared patterns (datetime, relationships,
  permissions)
- No entity group sub-modules to maintain single-module approach

**Testing Requirements:**

- Use existing Discord generators plus new generators for missing entities
- Focus-driven testing with `@tag :focus` during development
- Comprehensive integration testing with existing test resources

**Quality Standards:**

- 100% test coverage for main module transformation functions
- 95%+ test coverage for utility modules
- All transformations match steward patterns exactly

---

## Progress Tracking

Use the checkbox format above to track implementation progress. Mark tasks
completed immediately after finishing each substep. This provides clear
visibility into progress and helps identify any blockers or issues early in the
implementation process.

**Next Step:** Begin Phase 1 with creating the main change module foundation,
following the detailed task breakdown and TDD requirements outlined above.
