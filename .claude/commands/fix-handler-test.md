# Fix Handler Test

Apply quality test patterns to fix a handler test file.

## Command Behavior

When the user provides a test file path, analyze and refactor it using the
established quality patterns from AutoModerationRule tests.

## Quality Test Patterns to Apply

### 1. Proper Test Data Setup with Dependencies

- Create full dependency chains for all foreign key relationships
- Use generators with explicit relationship IDs
- Call `*_from_discord!` to persist all prerequisite records

Example:

```elixir
# Create dependency chain
guild = guild()
user = user()
guild_member = guild_member(%{guild_id: guild.id, user_id: user.id})

# Persist all records
TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)
TestApp.Discord.guild_member_from_discord!(%{data: guild_member}, authorize?: false)
```

### 2. Consistent Authorization Bypass

- Use `authorize?: false` explicitly in all test setup and assertions
- Make intent clear that tests focus on business logic, not policies

```elixir
# Read operations
assert [created] = TestApp.Discord.Resource.read!(authorize?: false)

# Write operations
TestApp.Discord.resource_from_discord!(%{data: data}, authorize?: false)
```

### 3. Pattern Matching for Assertions

- Replace `length(list) == n` + `hd(list)` with pattern matching
- Fail fast with clear error messages

```elixir
# Before
items = Resource.read!()
assert length(items) == 1
item = hd(items)

# After
[item] = Resource.read!(authorize?: false)
```

### 4. Verify Relationships by Loading and Checking Related Records

- **CRITICAL**: All Discord-sourced IDs must use `*_discord_id` field names (per
  CLAUDE.md project instructions)
- **ALWAYS verify relationships by loading them**, not just checking foreign key
  attributes
- This proves relationships are correctly configured and functional
- Create all prerequisite records before testing

```elixir
# Generator creates: %{guild_id: 123, user_id: 456, channel_id: 789}
# Resource stores as: guild_discord_id, user_discord_id, channel_discord_id

# Create prerequisite records
guild_data = guild(%{id: event_data.guild_id})
user_data = user(%{id: event_data.user_id})
channel_data = channel(%{guild_id: guild_data.id, id: event_data.channel_id})

TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

# Load ALL relationships when reading
[created] =
  Resource
  |> Ash.Query.load([:guild, :user, :channel])
  |> Ash.read!(authorize?: false)

# Assert on related records' IDs (not foreign keys)
assert created.guild.discord_id == event_data.guild_id
assert created.user.discord_id == event_data.user_id
assert created.channel.discord_id == event_data.channel_id
```

**Why verify relationships this way:**

- Proves `belongs_to` relationships are correctly defined
- Verifies `source_attribute` and `destination_attribute` are correct
- Confirms related records can be navigated (e.g., `event.guild.discord_id`)
- Tests realistic usage patterns (handlers often load relationships)
- Catches configuration errors that checking FKs alone would miss

**Resources should have `belongs_to` relationships:**

```elixir
# In resource definition:
belongs_to :guild, TestApp.Discord.Guild do
  source_attribute(:guild_discord_id)
  destination_attribute(:discord_id)
  attribute_writable?(true)
end

belongs_to :user, TestApp.Discord.User do
  source_attribute(:user_discord_id)
  destination_attribute(:discord_id)
  attribute_writable?(true)
end

belongs_to :channel, TestApp.Discord.Channel do
  source_attribute(:channel_discord_id)
  destination_attribute(:discord_id)
  attribute_writable?(true)
end
```

**Note**: Polymorphic fields (like audit log `target_discord_id`) are attributes
only, no relationships

### 5. Use `new!` vs `new` Appropriately

- Use `new!` when payload creation should succeed (cleaner, fails fast)
- Only use `{:ok, payload} = new(data)` when testing error cases

```elixir
# Before
{:ok, payload} = Payloads.Resource.new(data)

# After (when success is expected)
payload = Payloads.Resource.new!(data)
```

### 6. Remove Redundant Comments

- Remove comments that duplicate what code clearly shows
- Keep comments only for non-obvious business logic

```elixir
# Before
# Verify resource was created in database
resources = Resource.read!()

# After
[created] = Resource.read!(authorize?: false)
```

### 7. Realistic Test Scenarios

- Mirror actual handler execution paths
- Create records using `from_discord!` like real events would
- Test with realistic data relationships

### 8. Test Tags for Organization

- Add `@tag :fixed` to tests refactored to new patterns
- Helps track test evolution and run specific subsets

## Execution Steps

1. **Read the test file** to understand current structure
2. **Read the resource definition** to identify all `belongs_to` relationships
3. **Analyze patterns** - identify which quality improvements apply
4. **Create todo list** with specific refactoring tasks
5. **Apply refactorings systematically**:
   - Fix data setup (create dependency chains for ALL relationships)
   - Create prerequisite records for all `belongs_to` relationships
   - Add `authorize?: false` throughout
   - Convert to pattern matching
   - **Load ALL relationships** using
     `Ash.Query.load([:guild, :user, :channel, ...])`
   - **Assert on loaded relationships** - check `created.guild.discord_id`, not
     `created.guild_discord_id`
   - Use `new!` where appropriate
   - Remove redundant comments
   - Add `@tag :fixed` to refactored tests
6. **Verify changes** - ensure tests still pass
7. **Commit with descriptive message** following the pattern:

   ```
   test: apply quality patterns to [handler name] tests

   - Create proper dependency chains for all relationships
   - Load and verify all belongs_to relationships
   - Add explicit authorize?: false for test operations
   - Use pattern matching for cleaner assertions
   - Assert on loaded relationships instead of foreign keys
   - Use new! for expected-success payload creation
   - Remove redundant comments
   ```

## Example Transformation

### Before

```elixir
test "creates guild scheduled event in database" do
  event_id = generate_snowflake()
  guild_id = generate_snowflake()

  event_data = %Nostrum.Struct.Guild.ScheduledEvent{
    id: event_id,
    guild_id: guild_id,
    channel_id: nil,
    creator_id: generate_snowflake(),
    name: "Test Event",
    ...
  }

  {:ok, event_payload} = Payloads.GuildScheduledEvent.new(event_data)
  assert :ok = GuildScheduledEvent.create(..., event_payload, ...)

  events =
    TestApp.Discord.GuildScheduledEvent
    |> Ash.Query.filter(discord_id: event_id)
    |> Ash.read!()

  assert length(events) == 1
  created_event = hd(events)
  assert created_event.discord_id == event_id
  assert created_event.guild_id == guild_id
end
```

### After

```elixir
@tag :fixed
test "creates guild scheduled event in database with all relationships" do
  # Create prerequisite records for ALL relationships
  guild_data = guild()
  channel_data = channel(%{guild_id: guild_data.id})
  creator_data = user()

  event_data =
    guild_scheduled_event(%{
      guild_id: guild_data.id,
      channel_id: channel_data.id,
      creator_id: creator_data.id,
      entity_type: 2
    })

  # Persist all prerequisite records
  TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
  TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
  TestApp.Discord.user_from_discord!(%{data: creator_data}, authorize?: false)

  event_payload = Payloads.GuildScheduledEvent.new!(event_data)
  assert :ok = GuildScheduledEvent.create(..., event_payload, ...)

  # Load ALL relationships to verify they work
  [created_event] =
    TestApp.Discord.GuildScheduledEvent
    |> Ash.Query.load([:guild, :channel, :creator])
    |> Ash.read!(authorize?: false)

  # Assert on loaded relationships (not foreign keys)
  assert created_event.discord_id == event_data.id
  assert created_event.guild.discord_id == event_data.guild_id
  assert created_event.channel.discord_id == event_data.channel_id
  assert created_event.creator.discord_id == event_data.creator_id
  assert created_event.name == event_data.name
end
```

## Notes

- Focus on one test file at a time for clarity
- Run tests after each major change to catch issues early
- If tests fail, investigate whether it's a test issue or actual bug
- Some tests may need resource structure investigation to understand field names
