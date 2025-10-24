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

### 4. Correct Field Name Assertions

- **CRITICAL**: All Discord-sourced IDs must use `*_discord_id` field names (per
  CLAUDE.md project instructions)
- Match against the generator data's non-prefixed field names
- This applies to ALL Discord IDs: user, guild, channel, role, owner, target,
  etc.

```elixir
# Generator creates: %{guild_id: 123, user_id: 456, owner_id: 789}
# Resource stores as: guild_discord_id, user_discord_id, owner_discord_id

assert created.guild_discord_id == data.guild_id
assert created.user_discord_id == data.user_id
assert created.owner_discord_id == data.owner_id
```

**Relationships for Discord IDs:**

- Resources should have `belongs_to` relationships for non-polymorphic Discord
  IDs
- Test that relationships work by checking the attribute values
- Polymorphic fields (like audit log `target_discord_id`) are attributes only,
  no relationships

```elixir
# In resource definition:
belongs_to :user, TestApp.Discord.User do
  source_attribute(:user_discord_id)
  destination_attribute(:discord_id)
  attribute_writable?(true)
end

# In test assertions:
assert created.user_discord_id == data.user_id
# Could also test relationship loading if needed
```

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
2. **Analyze patterns** - identify which quality improvements apply
3. **Create todo list** with specific refactoring tasks
4. **Apply refactorings systematically**:
   - Fix data setup (create dependency chains)
   - Add `authorize?: false` throughout
   - Convert to pattern matching
   - **Fix field name assertions** - ALL Discord IDs must use `*_discord_id`
     suffix
   - **Verify relationships** - Check if resource has proper `belongs_to`
     relationships for Discord IDs
   - Use `new!` where appropriate
   - Remove redundant comments
   - Add `@tag :fixed` to refactored tests
5. **Verify changes** - ensure tests still pass
6. **Commit with descriptive message** following the pattern:

   ```
   test: apply quality patterns to [handler name] tests

   - Create proper dependency chains for test data
   - Add explicit authorize?: false for test operations
   - Use pattern matching for cleaner assertions
   - Fix field name assertions to use *_discord_id
   - Use new! for expected-success payload creation
   - Remove redundant comments
   ```

## Example Transformation

### Before

```elixir
test "creates channel pins update in database" do
  pins_data = channel_pins_update()

  {:ok, pins_payload} = Payloads.ChannelPinsUpdateEvent.new(pins_data)
  assert :ok = ChannelPins.update(pins_payload, ws_state, context)

  pins_updates = TestApp.Discord.ChannelPinsUpdate.read!()
  assert length(pins_updates) == 1

  created_pins = hd(pins_updates)
  assert created_pins.channel_id == pins_data.channel_id
end
```

### After

```elixir
@tag :fixed
test "creates channel pins update in database" do
  guild = guild()
  channel = channel(%{guild_id: guild.id})

  TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
  TestApp.Discord.channel_from_discord!(%{data: channel}, authorize?: false)

  pins_data = channel_pins_update(%{
    channel_id: channel.id,
    guild_id: guild.id
  })

  pins_payload = Payloads.ChannelPinsUpdateEvent.new!(pins_data)
  assert :ok = ChannelPins.update(pins_payload, ws_state, context)

  [created_pins] = TestApp.Discord.ChannelPinsUpdate.read!(authorize?: false)

  assert created_pins.channel_discord_id == pins_data.channel_id
  assert created_pins.guild_discord_id == pins_data.guild_id
end
```

## Notes

- Focus on one test file at a time for clarity
- Run tests after each major change to catch issues early
- If tests fail, investigate whether it's a test issue or actual bug
- Some tests may need resource structure investigation to understand field names
