# Strategic Implementation Plan: AshDiscord FromDiscord Change System

**Topic:** Create configurable from_discord change implementation strategy
**Date:** 2025-09-20 **Status:** Planning Phase Complete

---

## Executive Summary

Create a single, configurable `AshDiscord.Changes.FromDiscord` module that
handles all Discord entity transformations through a `type` option. Based on the
comprehensive steward research showing universal patterns across 15 Discord
entity types, we can consolidate this into one clean, well-organized change
module.

**Strategic Decision:** Implement one configurable change module with type-based
dispatch and organized sub-modules for maintainability.

---

## Impact Analysis Summary

### Research Findings Validated

- ✅ **15 steward project modules** analyzed with universal patterns identified
- ✅ **Struct-first data flow** pattern proven across all implementations
- ✅ **Standard transformation logic** cataloged (datetime parsing, permission
  overwrites, key normalization)
- ✅ **Relationship auto-creation patterns** consistently implemented
- ✅ **Current AshDiscord architecture** supports the recommended approach

### Implementation Approach

All steward modules follow the same basic pattern:

1. Get Discord data (struct-first, API fallback)
2. Transform fields based on entity type
3. Manage relationships with auto-creation
4. Handle entity-specific edge cases

We can consolidate this into one module with type-based dispatch.

---

## Feature Specification

### Primary Features

#### 1. **Main Configurable Change Module**

- **Purpose**: Single change module handling all Discord entity types
- **Implementation**: `AshDiscord.Changes.FromDiscord` with `type` option
- **Usage**: `change {AshDiscord.Changes.FromDiscord, type: :user}`
- **Benefits**: One module to maintain, consistent behavior across all entity
  types

#### 2. **Type-Based Transformation Dispatch**

- **Purpose**: Handle entity-specific transformation logic
- **Implementation**: Pattern matching on `type` option to call appropriate
  transformation functions
- **Coverage**: All 15 Discord entity types found in steward research
- **Benefits**: Clear separation of concerns while maintaining single entry
  point

#### 3. **Organized Sub-Modules for Maintainability**

- **Purpose**: Keep individual transformation functions focused and testable
- **Implementation**: Split transformations into logical sub-modules
- **Coverage**: Grouping by complexity/functionality (simple, datetime,
  permissions, etc.)
- **Benefits**: Easier to maintain, test, and debug individual transformations

### User Stories with Acceptance Criteria

#### As an application developer using AshDiscord:

- **Given** I need to transform Discord User data in my Ash resource
- **When** I add `change {AshDiscord.Changes.FromDiscord, type: :user}` to my
  resource
- **Then** The transformation works with both struct and API fetch patterns
- **And** All user-specific fields are properly mapped and transformed

#### As an application developer supporting multiple Discord entities:

- **Given** I have User, Guild, and Message resources
- **When** I use the same change module with different type options
- **Then** Each resource gets the appropriate transformation logic
- **And** The behavior is consistent across all entity types

#### As a maintainer debugging Discord integration issues:

- **Given** There's an error in Discord Guild transformation
- **When** I investigate the issue
- **Then** I can easily locate the guild-specific transformation code
- **And** The error doesn't affect other Discord entity types

---

## Technical Design

### Architecture Overview

```
lib/ash_discord/changes/
├── from_discord.ex              # Main change module (NEW)
└── from_discord/               # Sub-modules for organization (NEW)
    ├── transformations.ex      # Shared transformation utilities
    └── api_fetchers.ex         # Entity-specific API fetch functions
```

### Core Implementation

#### 1. **Main Change Module** - `AshDiscord.Changes.FromDiscord`

```elixir
defmodule AshDiscord.Changes.FromDiscord do
  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{Transformations, ApiFetchers}

  @impl true
  def change(changeset, opts, _context) do
    entity_type = Keyword.fetch!(opts, :type)

    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case get_discord_data(changeset, entity_type) do
        {:ok, discord_data} ->
          transform_entity(changeset, discord_data, entity_type)
        {:error, reason} ->
          Ash.Changeset.add_error(changeset, :discord_fetch_error, reason)
      end
    end)
  end

  # Struct-first data flow pattern from steward research
  defp get_discord_data(changeset, entity_type) do
    case Ash.Changeset.get_argument(changeset, :discord_struct) do
      %{id: _} = struct ->
        {:ok, struct}  # Primary: use provided struct
      nil ->
        ApiFetchers.fetch_from_api(changeset, entity_type)  # Fallback: API fetch
      invalid ->
        {:error, "Invalid discord_struct: #{inspect(invalid)}"}
    end
  end

  # Type-based dispatch to appropriate transformation functions
  defp transform_entity(changeset, discord_data, entity_type) do
    case entity_type do
      :user ->
        transform_user(changeset, discord_data)

      :guild ->
        transform_guild(changeset, discord_data)

      :guild_member ->
        transform_guild_member(changeset, discord_data)

      :channel ->
        transform_channel(changeset, discord_data)

      :message ->
        transform_message(changeset, discord_data)

      :role ->
        transform_role(changeset, discord_data)

      :emoji ->
        transform_emoji(changeset, discord_data)

      :voice_state ->
        transform_voice_state(changeset, discord_data)

      :webhook ->
        transform_webhook(changeset, discord_data)

      :invite ->
        transform_invite(changeset, discord_data)

      :message_attachment ->
        transform_message_attachment(changeset, discord_data)

      :message_reaction ->
        transform_message_reaction(changeset, discord_data)

      :typing_indicator ->
        transform_typing_indicator(changeset, discord_data)

      :sticker ->
        transform_sticker(changeset, discord_data)

      :interaction ->
        transform_interaction(changeset, discord_data)

      type ->
        Ash.Changeset.add_error(changeset, :unsupported_discord_type,
          "Unsupported Discord entity type: #{type}")
    end
  end

  # User transformation (from steward User pattern)
  defp transform_user(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:discord_username, discord_data.username)
    |> Ash.Changeset.force_change_attribute(:discord_avatar, discord_data.avatar)
    |> Ash.Changeset.force_change_attribute(:email,
         Transformations.generate_discord_email(discord_data.id))
  end

  # Guild transformation (from steward Guild pattern)
  defp transform_guild(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:icon, discord_data.icon)
    |> Ash.Changeset.force_change_attribute(:owner_id, discord_data.owner_id)
  end

  # GuildMember transformation (from steward GuildMember pattern)
  defp transform_guild_member(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:user_discord_id, discord_data.user.id)
    |> Ash.Changeset.force_change_attribute(:nick, discord_data.nick)
    |> Ash.Changeset.force_change_attribute(:avatar, discord_data.avatar)
    |> Ash.Changeset.force_change_attribute(:deaf, discord_data.deaf || false)
    |> Ash.Changeset.force_change_attribute(:mute, discord_data.mute || false)
    |> Transformations.set_datetime_field(:joined_at, discord_data.joined_at)
    |> Transformations.set_datetime_field(:premium_since, discord_data.premium_since)
    |> Transformations.manage_guild_relationship(discord_data.guild_id)
    |> Transformations.manage_user_relationship(discord_data.user.id)
  end

  # Channel transformation (from steward Channel pattern)
  defp transform_channel(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:type, discord_data.type)
    |> Ash.Changeset.force_change_attribute(:position, discord_data.position)
    |> Ash.Changeset.force_change_attribute(:topic, discord_data.topic)
    |> Ash.Changeset.force_change_attribute(:nsfw, discord_data.nsfw || false)
    |> Ash.Changeset.force_change_attribute(:parent_id, discord_data.parent_id)
    |> Ash.Changeset.force_change_attribute(:permission_overwrites,
         Transformations.transform_permission_overwrites(discord_data.permission_overwrites))
    |> Transformations.manage_guild_relationship(discord_data.guild_id)
  end

  # Message transformation (from steward Message pattern)
  defp transform_message(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:content, discord_data.content)
    |> Ash.Changeset.force_change_attribute(:author_id, discord_data.author.id)
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> Ash.Changeset.force_change_attribute(:timestamp, discord_data.timestamp)
    |> Transformations.manage_channel_relationship(discord_data.channel_id)
    |> handle_message_attachments(discord_data.attachments)
  end

  # Role transformation (from steward Role pattern)
  defp transform_role(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:color, discord_data.color)
    |> Ash.Changeset.force_change_attribute(:permissions, to_string(discord_data.permissions))
    |> Transformations.manage_guild_relationship(discord_data.guild_id)
  end

  # Emoji transformation (from steward Emoji pattern)
  defp transform_emoji(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, discord_data.id)
    |> Ash.Changeset.force_change_attribute(:name, discord_data.name)
    |> Ash.Changeset.force_change_attribute(:animated, discord_data.animated || false)
    |> Transformations.manage_guild_relationship(discord_data.guild_id)
  end

  # VoiceState transformation (from steward VoiceState pattern)
  defp transform_voice_state(changeset, discord_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:user_id, discord_data.user_id)
    |> Ash.Changeset.force_change_attribute(:channel_id, discord_data.channel_id)
    |> Ash.Changeset.force_change_attribute(:session_id, discord_data.session_id)
    |> Ash.Changeset.force_change_attribute(:deaf, discord_data.deaf || false)
    |> Ash.Changeset.force_change_attribute(:mute, discord_data.mute || false)
    |> Ash.Changeset.force_change_attribute(:self_deaf, discord_data.self_deaf || false)
    |> Ash.Changeset.force_change_attribute(:self_mute, discord_data.self_mute || false)
    |> Transformations.set_datetime_field(:request_to_speak_timestamp, discord_data.request_to_speak_timestamp)
  end

  # Additional entity transformations following same patterns...
  # (webhook, invite, message_attachment, message_reaction, typing_indicator, sticker, interaction)

  defp handle_message_attachments(changeset, attachments) when is_list(attachments) do
    attachment_ids = Enum.map(attachments, & &1.id)
    Transformations.manage_attachments_relationship(changeset, attachment_ids)
  end
  defp handle_message_attachments(changeset, _), do: changeset

  # Placeholder implementations for remaining entity types
  defp transform_webhook(changeset, discord_data), do: changeset # TODO: implement
  defp transform_invite(changeset, discord_data), do: changeset # TODO: implement
  defp transform_message_attachment(changeset, discord_data), do: changeset # TODO: implement
  defp transform_message_reaction(changeset, discord_data), do: changeset # TODO: implement
  defp transform_typing_indicator(changeset, discord_data), do: changeset # TODO: implement
  defp transform_sticker(changeset, discord_data), do: changeset # TODO: implement
  defp transform_interaction(changeset, discord_data), do: changeset # TODO: implement
end
```

#### 2. **Shared Transformations Module** - `AshDiscord.Changes.FromDiscord.Transformations`

```elixir
defmodule AshDiscord.Changes.FromDiscord.Transformations do
  # DateTime parsing (from steward GuildMember pattern)
  def set_datetime_field(changeset, field, nil), do: changeset
  def set_datetime_field(changeset, field, iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, datetime, _offset} ->
        Ash.Changeset.force_change_attribute(changeset, field, datetime)
      {:error, _} ->
        changeset  # Graceful degradation
    end
  end

  # Discord email generation (from steward User pattern)
  def generate_discord_email(discord_id, domain \\ "discord.local") do
    "discord+#{discord_id}@#{domain}"
  end

  # Permission overwrites (from steward Channel pattern)
  def transform_permission_overwrites(nil), do: []
  def transform_permission_overwrites(overwrites) when is_list(overwrites) do
    Enum.map(overwrites, fn overwrite ->
      %{
        "id" => overwrite.id,
        "type" => overwrite.type,
        "allow" => to_string(overwrite.allow),
        "deny" => to_string(overwrite.deny)
      }
    end)
  end

  # Standard relationship management (from steward universal pattern)
  def manage_guild_relationship(changeset, guild_id) do
    Ash.Changeset.manage_relationship(changeset, :guild, guild_id,
      type: :append_and_remove,
      on_no_match: {:create, :from_discord},
      use_identities: [:discord_id],
      value_is_key: :discord_id
    )
  end

  def manage_user_relationship(changeset, user_id) do
    Ash.Changeset.manage_relationship(changeset, :user, user_id,
      type: :append_and_remove,
      on_no_match: {:create, :from_discord},
      use_identities: [:discord_id],
      value_is_key: :discord_id
    )
  end

  def manage_channel_relationship(changeset, channel_id) do
    Ash.Changeset.manage_relationship(changeset, :channel, channel_id,
      type: :append_and_remove,
      on_no_match: {:create, :from_discord},
      use_identities: [:discord_id],
      value_is_key: :discord_id
    )
  end
end
```

### Usage Examples

Based on steward patterns, usage would be:

```elixir
# In User resource
create :from_discord do
  change {AshDiscord.Changes.FromDiscord, type: :user}
end

# In Guild resource
create :from_discord do
  change {AshDiscord.Changes.FromDiscord, type: :guild}
end

# In GuildMember resource (complex with datetime parsing)
create :from_discord do
  change {AshDiscord.Changes.FromDiscord, type: :guild_member}
end

# In Channel resource (complex with permission overwrites)
create :from_discord do
  change {AshDiscord.Changes.FromDiscord, type: :channel}
end
```

---

## Implementation Strategy

### Primary Approach: Single Configurable Module with Sub-Module Organization

**Why This Approach:**

- ✅ **Simple and straightforward** - one change module to maintain
- ✅ **Type-based dispatch** makes behavior clear and predictable
- ✅ **Sub-modules for organization** keep code focused and testable
- ✅ **Follows steward patterns** proven to work in production
- ✅ **Easy to extend** - add new types by extending the appropriate sub-module

**Benefits Over Separate Modules:**

- Single entry point and consistent API
- Shared transformation utilities without duplication
- Easier to maintain type support across all entities
- Consistent error handling and data flow patterns

**Benefits Over Complex Configuration:**

- No DSL complexity or configuration explosion
- Simple type option that's easy to understand and debug
- Explicit code paths that are easy to trace and test

---

## Implementation Phases

### Phase 1: Core Module and Simple Entities (Week 1)

**Objectives:**

- Create main `AshDiscord.Changes.FromDiscord` module with type dispatch
- Implement `SimpleEntities` sub-module for User, Guild, Role, Emoji
- Set up shared `Transformations` utilities
- Create comprehensive test suite

**Deliverables:**

- `lib/ash_discord/changes/from_discord.ex` - Main change module with core
  transformations
- `lib/ash_discord/changes/from_discord/transformations.ex` - Shared utilities
- Extended Discord generators for missing entity types (permission_overwrite,
  voice_state, message_attachment, etc.)
- Full test coverage using generators instead of hardcoded data

**Success Criteria:**

- User, Guild, Role, and Emoji types working with struct-first pattern
- All transformations match steward research patterns exactly
- Tests use existing Discord generators plus new generators for missing entities
- Integration with existing test resources validated

### Phase 2: Complex and Datetime Entities (Week 2)

**Objectives:**

- Implement `ComplexEntities` sub-module for Channel, Message, Webhook
- Implement `DatetimeEntities` sub-module for GuildMember, VoiceState, Invite
- Add `ApiFetchers` sub-module for API fallback functionality
- Extend test coverage to all entity types

**Deliverables:**

- `lib/ash_discord/changes/from_discord/complex_entities.ex` - Complex
  transformations
- `lib/ash_discord/changes/from_discord/datetime_entities.ex` - Datetime
  transformations
- `lib/ash_discord/changes/from_discord/api_fetchers.ex` - API fetch utilities
- Complete test coverage for all 15 Discord entity types

**Success Criteria:**

- All 15 Discord entity types from steward research supported
- Complex transformations (permission overwrites, datetime parsing) working
  correctly
- API fallback functionality tested and working
- Performance equivalent to individual change modules

### Phase 3: Integration and Documentation (Week 3)

**Objectives:**

- Update existing test resources to use new configurable change
- Create comprehensive documentation and examples
- Performance optimization and benchmarking
- Migration guide for existing implementations

**Deliverables:**

- Updated test resources demonstrating all entity types
- Complete documentation with examples for each Discord entity type
- Performance benchmarks and optimization improvements
- Migration guide for moving from manual implementations

**Success Criteria:**

- All existing test resources successfully use new change module
- Documentation enables easy adoption of new patterns
- Performance meets or exceeds manual implementation benchmarks
- Clear migration path for existing Discord integrations

---

## Quality and Testing Strategy

### Test Architecture

**Type-Based Testing:**

- Unit tests for each entity type transformation
- Integration tests with real Nostrum struct data
- Property-based testing for transformation utilities
- Error handling validation for all edge cases

**Sub-Module Testing:**

- Focused test suites for each sub-module (SimpleEntities, ComplexEntities,
  etc.)
- Shared transformation utility testing with comprehensive edge cases
- API fetcher testing with mocked Nostrum API calls

**Integration Testing:**

- Full change module testing with all supported entity types
- Test coverage with existing AshDiscord test resources
- Performance benchmarking against individual change modules

### Testing Patterns

**Using Existing Discord Generators:**

```elixir
defmodule AshDiscord.Changes.FromDiscordTest do
  use ExUnit.Case
  import AshDiscord.Test.Generators.Discord

  describe "User entity transformation" do
    test "transforms Discord user struct to changeset attributes" do
      user_struct = user(%{username: "testuser"})

      changeset = Ash.Changeset.new(MyApp.Discord.User)
      |> Ash.Changeset.set_argument(:discord_struct, user_struct)

      result = AshDiscord.Changes.FromDiscord.change(changeset, [type: :user], %{})

      assert Ash.Changeset.get_attribute(result, :discord_id) == user_struct.id
      assert Ash.Changeset.get_attribute(result, :discord_username) == "testuser"
      assert Ash.Changeset.get_attribute(result, :email) == "discord+#{user_struct.id}@discord.local"
    end
  end

  describe "GuildMember entity transformation" do
    test "handles datetime parsing correctly" do
      guild_struct = guild()
      user_struct = user()
      member_struct = member(%{
        guild_id: guild_struct.id,
        user: user_struct,
        joined_at: "2023-01-01T00:00:00Z"
      })

      changeset = Ash.Changeset.new(MyApp.Discord.GuildMember)
      |> Ash.Changeset.set_argument(:discord_struct, member_struct)

      result = AshDiscord.Changes.FromDiscord.change(changeset, [type: :guild_member], %{})

      joined_at = Ash.Changeset.get_attribute(result, :joined_at)
      assert %DateTime{} = joined_at
      assert DateTime.to_iso8601(joined_at) == "2023-01-01T00:00:00Z"
    end
  end

  describe "Channel entity transformation" do
    test "handles permission overwrites correctly" do
      guild_struct = guild()
      channel_struct = channel(%{
        guild_id: guild_struct.id,
        permission_overwrites: [permission_overwrite()]
      })

      changeset = Ash.Changeset.new(MyApp.Discord.Channel)
      |> Ash.Changeset.set_argument(:discord_struct, channel_struct)

      result = AshDiscord.Changes.FromDiscord.change(changeset, [type: :channel], %{})

      overwrites = Ash.Changeset.get_attribute(result, :permission_overwrites)
      assert is_list(overwrites)
      assert length(overwrites) == 1
    end
  end
end
```

**Additional Generators Needed:**

```elixir
defmodule AshDiscord.Test.Generators.Discord do
  # ... existing generators ...

  # Add missing generators needed for steward patterns
  def permission_overwrite(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      type: Faker.Util.pick([0, 1]), # 0 = role, 1 = member
      allow: Faker.random_between(0, 2147483647),
      deny: Faker.random_between(0, 2147483647)
    }

    merge_attrs(defaults, attrs)
  end

  def voice_state(attrs \\ %{}) do
    defaults = %{
      guild_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      user_id: generate_snowflake(),
      session_id: Faker.UUID.v4(),
      deaf: false,
      mute: false,
      self_deaf: false,
      self_mute: false,
      self_stream: false,
      self_video: false,
      suppress: false,
      request_to_speak_timestamp: nil
    }

    merge_attrs(defaults, attrs)
  end

  def message_attachment(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      filename: "#{Faker.Lorem.word()}.#{Faker.Util.pick(["png", "jpg", "pdf", "txt"])}",
      size: Faker.random_between(1024, 10_485_760), # 1KB to 10MB
      url: "https://cdn.discordapp.com/attachments/#{generate_snowflake()}/#{generate_snowflake()}/file.png",
      proxy_url: "https://media.discordapp.net/attachments/#{generate_snowflake()}/#{generate_snowflake()}/file.png",
      height: Faker.random_between(100, 2000),
      width: Faker.random_between(100, 2000),
      content_type: "image/png"
    }

    merge_attrs(defaults, attrs)
  end

  def message_reaction(attrs \\ %{}) do
    defaults = %{
      count: Faker.random_between(1, 50),
      me: false,
      emoji: emoji()
    }

    merge_attrs(defaults, attrs)
  end

  def typing_indicator(attrs \\ %{}) do
    defaults = %{
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake(),
      user_id: generate_snowflake(),
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      member: member()
    }

    merge_attrs(defaults, attrs)
  end

  def sticker(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      pack_id: generate_snowflake(),
      name: Faker.Lorem.word(),
      description: Faker.Lorem.sentence(),
      tags: Faker.Lorem.word(),
      type: 1,
      format_type: 1,
      available: true,
      guild_id: generate_snowflake(),
      user: user(),
      sort_value: Faker.random_between(1, 100)
    }

    merge_attrs(defaults, attrs)
  end
end
```

---

## Success Criteria

### Technical Success Metrics

- **Code Consolidation**: All 15 Discord entity types supported in single change
  module
- **Pattern Consistency**: All transformations follow proven steward patterns
  exactly
- **Test Coverage**: 100% coverage for main module, 95%+ for sub-modules
- **Performance**: No regression vs. individual change modules
- **Maintainability**: Clear code organization with focused sub-modules

### Functional Success Metrics

- **Type Support**: All Discord entity types from steward research working
  correctly
- **Struct-First Pattern**: Primary data flow using provided Discord structs
- **API Fallback**: Graceful fallback to Discord API when no struct provided
- **Relationship Management**: Auto-creation of related Discord entities working
- **Error Handling**: Consistent error patterns across all entity types

### Quality Assurance Checklist

#### Phase 1 Complete:

- [ ] Main change module with type dispatch working
- [ ] Primary entities (User, Guild, Role, Emoji) implemented and tested
- [ ] Shared transformation utilities created and tested
- [ ] Integration with existing test resources validated

#### Phase 2 Complete:

- [ ] All remaining entity transformations implemented in main module
- [ ] API fetcher utilities created and tested
- [ ] All 15 Discord entity types supported

#### Phase 3 Complete:

- [ ] Documentation complete with examples for all entity types
- [ ] Performance benchmarks meet targets
- [ ] Migration guide available for existing implementations
- [ ] All existing test resources updated successfully

---

## Next Steps

### Immediate Actions

1. **Create feature branch**: `feature/configurable-from-discord-change`
2. **Set up module structure**: Create main module and sub-module files
3. **Begin Phase 1**: Start with core module and simple entity transformations
4. **Set up comprehensive testing**: Create test structure for all entity types

The plan provides a straightforward path to consolidate all Discord entity
transformations into one well-organized, type-based change module that follows
the proven steward patterns while maintaining simplicity and maintainability.

**Planning Phase Complete** - Ready for breakdown phase with clear, simple
implementation approach.
