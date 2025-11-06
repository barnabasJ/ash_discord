# Fix From Discord Test

Apply quality test patterns to fix a from_discord change test file.

## Cleanup Phase Context

**IMPORTANT**: We are in a cleanup phase of ash_discord where:

- Only tests tagged with `:fixed` are currently passing
- Tests without `:fixed` tag may not be working yet
- **DO NOT break any `:fixed` tests** - they represent working functionality
- After refactoring and verifying tests, **mark them with `@tag :fixed`**
- This helps track progress through the cleanup phase

## Command Behavior

When the user provides a test file path, analyze and refactor it using the
established quality patterns from GuildMember and User from_discord tests.

## Quality Test Patterns to Apply

### 1. Comprehensive Test Structure

Tests should cover three main areas:

- **struct-first pattern**: Creating from Discord data structs
- **API fallback pattern**: Creating from identity using Nostrum API (when
  applicable)
- **upsert behavior**: Verify updates instead of duplicates (struct-first only)

**Note**: Do NOT include error handling tests (invalid data formats, missing
required fields, etc.). We assume correct data from Discord and focus only on
successful transformation patterns.

### 2. Mock Related Resource API Calls

- **CRITICAL**: For resources with relationships, mock the Nostrum API calls
  that related resources would make
- Example: Testing GuildMember means mocking `Nostrum.Api.User.get` and
  `Nostrum.Api.Guild.get`
- This allows the from_discord change to create related records via their own
  from_discord actions
- **DO NOT pre-create related records** - let the change handle it via API mocks
- **DO NOT add `Mimic.copy` in setup** - it's already done in test_helper.exs
  for all Nostrum.Api modules
- **Inline mocks directly in each test** - no helper functions needed

Example:

```elixir
test "creates guild member from discord struct with all attributes" do
  Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
    {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
  end)

  Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id ->
    {:ok, guild(%{id: guild_id, name: "Test Guild"})}
  end)

  member_struct =
    guild_member(%{
      user_id: 123_456_789,
      nick: "TestNick",
      joined_at: to_unix_ms("2023-01-15T10:30:00Z"),
      deaf: false,
      mute: false
    })

  result =
    TestApp.Discord.guild_member_from_discord(%{
      data: member_struct,
      identity: %{guild_discord_id: 555_666_777}
    })

  assert {:ok, created_member} = result
  assert created_member.user_discord_id == member_struct.user_id
  assert created_member.nick == member_struct.nick
end
```

### 2.1. CRITICAL: Override Generator Relationship IDs in Mocks

**IMPORTANT**: When mocking Nostrum API calls that return generated structs, you MUST explicitly override ALL relationship IDs (like `guild_id`, `channel_id`, `user_id`, etc.) to match your test's IDs. Otherwise, generators will create random IDs for relationships, causing multiple from_discord calls and exhausting your mocks.

**Problem**: Generators often default relationship IDs to `generate_snowflake()`, creating random IDs. When a related resource is created with a random relationship ID, it triggers from_discord for that relationship. Then when your main resource tries to create the relationship with your test ID, it triggers from_discord again, but the mock is already exhausted (expect defaults to 1 call).

**Solution**: Always override relationship IDs in generator mocks to match your test IDs:

```elixir
# ❌ WRONG - channel will have random guild_id, triggering unexpected Guild creation
expect(Nostrum.Api.Channel, :get, fn id ->
  {:ok, channel(%{id: id, name: "test-channel", type: 0})}
end)

# ✅ CORRECT - channel uses your test guild_id
guild_id = 111_222_333

expect(Nostrum.Api.Channel, :get, fn id ->
  {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
end)

# Another example: member with user relationship
user_id = 987_654_321

expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
  {:ok, guild_member(%{user_id: user_id, nick: "Test"})}  # ✅ user_id matches test
end)
```

**When to do this**: Override relationship IDs whenever:
- The generator has `guild_id`, `channel_id`, `user_id`, or any other `*_id` field
- The mocked struct will be used to create related resources via from_discord
- You're getting `:api_unavailable` errors despite setting up mocks

**Debugging tip**: Add temporary IO.inspect to the from_discord change to see which IDs are being passed. Unexpected IDs indicate a generator is creating random relationship IDs.

### 3. Struct-First Pattern Tests

- Test creating resources from Discord struct data
- Use generators to create test data
- Inline mock related resource API calls at the start of each test
- Test various attribute combinations and edge cases
- No authorization bypass needed - these are action tests, not handler tests
- **CRITICAL**: Load and verify ALL relationships that exist on the resource
  - After validating the resource (step 2), you know which `belongs_to`
    relationships exist
  - Pass `load: [:rel1, :rel2, :rel3]` to the `from_discord!` call for ALL
    relationships
  - Assert on EVERY loaded relationship: `record.relationship.discord_id`
  - This verifies the from_discord change created related records correctly via
    API mocks
  - Do NOT assert on foreign key attributes (`*_discord_id`) - only assert on
    loaded relationships
  - Exception: Polymorphic fields without relationships - assert on attribute
    value directly

Example:

```elixir
describe "struct-first pattern" do
  test "creates resource from discord struct with all attributes" do
    user_id = 555_666_777
    guild_id = 999_888_777

    Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
      {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
    end)

    Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
      {:ok, guild(%{id: guild_id, name: "Test Guild"})}
    end)

    resource_struct =
      resource(%{
        id: 123_456_789,
        user_id: user_id,
        guild_id: guild_id,
        name: "Test Resource"
      })

    created =
      TestApp.Discord.resource_from_discord!(%{data: resource_struct},
        load: [:user, :guild]
      )

    assert created.name == resource_struct.name
    assert created.user.discord_id == user_id
    assert created.guild.discord_id == guild_id
  end

  test "handles nil optional field" do
    resource_struct = resource(%{id: 987_654_321, optional_field: nil})

    created = TestApp.Discord.resource_from_discord!(%{data: resource_struct})

    assert created.optional_field == nil
  end
end
```

### 4. API Fallback Pattern Tests (When Applicable)

- **CRITICAL**: Only test API fallback if the resource can be fetched from
  Discord API via Nostrum
- Check Nostrum.Api modules for available API endpoints (e.g.,
  `Nostrum.Api.User.get/1`, `Nostrum.Api.Guild.member/2`)
- Inline mock all Nostrum API calls using Mimic.expect
- Mock both the primary resource API call AND related resource API calls
- **Test in separate describe block** - do NOT test in upsert block

Example:

```elixir
describe "API fallback pattern" do
  test "fetches resource from API when data not provided" do
    guild_id = 555_666_777
    user_id = 999_888_777

    # Mock the primary resource API call
    Mimic.expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
      {:ok,
       guild_member(%{
         user_id: user_id,
         nick: "API_Fetched_Nick",
         joined_at: to_unix_ms("2023-06-15T10:00:00Z"),
         deaf: false,
         mute: true
       })}
    end)

    # Mock related resource API calls
    Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
      {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
    end)

    Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
      {:ok, guild(%{id: guild_id, name: "Test Guild"})}
    end)

    result =
      TestApp.Discord.resource_from_discord(%{
        identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
      })

    assert {:ok, created} = result
    assert created.user_discord_id == user_id
    assert created.guild_discord_id == guild_id
    assert created.nick == "API_Fetched_Nick"
  end
end
```

**Note**: Skip API fallback tests entirely if:

- No Nostrum API endpoint exists for fetching the resource
- The resource is only created through events, not fetchable directly

**IMPORTANT - Resources Without API Fallback:**

For resources that don't support API fallback (like Integration, which can only
be fetched via `Nostrum.Api.Guild.integrations/1`):

1. **Remove the `identity` argument** from the action definition entirely

   - The identity argument is specifically for API fallback (fetching from
     Discord when data is nil)
   - If the resource doesn't support individual fetching, the identity serves no
     purpose
   - Example: `argument(:data, ..., allow_nil?: false)` (no identity argument)

2. **Get IDs from the payload** instead of from identity

   - Most payloads include necessary IDs like `guild_id` in the data structure
   - Read these directly: `integration_data.guild_id`

3. **Update documentation** to clarify no API fallback support

   - Change implementation should document why identity isn't accepted
   - Test module should explain the resource can't be fetched individually

4. **Tests don't pass identity** - just `%{data: payload}`

### 5. Upsert Behavior Tests

- Verify that calling `from_discord` twice with same identity updates the record
- Check that Ash ID remains the same (proves upsert, not duplicate creation)
- Test attribute updates work correctly
- Inline mock related resource API calls
- **IMPORTANT**: Test upsert with struct-first pattern only, NOT API fallback

Example:

```elixir
describe "upsert behavior" do
  test "updates existing resource instead of creating duplicate" do
    Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
      {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
    end)

    Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id ->
      {:ok, guild(%{id: guild_id, name: "Test Guild"})}
    end)

    user_id = 555_666_777
    guild_id = 111_222_333

    # Create initial resource
    initial_struct =
      guild_member(%{
        user_id: user_id,
        nick: "OriginalNick",
        joined_at: to_unix_ms("2023-01-01T00:00:00Z"),
        deaf: false,
        mute: false
      })

    {:ok, original} =
      TestApp.Discord.guild_member_from_discord(%{
        data: initial_struct,
        identity: %{guild_discord_id: guild_id}
      })

    # Update same resource with new data
    updated_struct =
      guild_member(%{
        user_id: user_id,
        nick: "UpdatedNick",
        joined_at: to_unix_ms("2023-01-01T00:00:00Z"),
        deaf: true,
        mute: true
      })

    {:ok, updated} =
      TestApp.Discord.guild_member_from_discord(%{
        data: updated_struct,
        identity: %{guild_discord_id: guild_id}
      })

    # Should be same record (same Ash ID)
    assert updated.id == original.id
    assert updated.user_discord_id == original.user_discord_id

    # But with updated attributes
    assert updated.nick == "UpdatedNick"
    assert updated.deaf == true
    assert updated.mute == true
  end
end
```

### 6. Test Organization

- Group tests by behavior using `describe` blocks
- Use clear, descriptive test names
- Add module documentation explaining what's being tested
- Add `use Mimic` at module level if any tests need mocking
- Inline all mocks directly in tests - no helper functions

### 7. Comments

**CRITICAL**: Do NOT add obvious comments that just repeat what the code shows.

- ❌ BAD: `# Mock User API for owner` before
  `Mimic.expect(Nostrum.Api.User, :get, ...)`
- ❌ BAD: `# Should be same record` before `assert updated.id == original.id`
- ❌ BAD: `# Voice channel` inline with `type: 2`
- ❌ BAD: `# Create initial resource` before creating test data
- ✅ GOOD: Inline comments explaining non-obvious test data structure (e.g.,
  role vs member permission overwrites)

Comments should only explain **WHY** something is done when it's not obvious
from the code, not **WHAT** is being done.

### 8. Mimic Setup

- **DO NOT add `Mimic.copy` calls** - already handled in test_helper.exs
- Only add `use Mimic` at module level if testing needs mocking
- Inline `Mimic.expect` calls at the start of each test
- Verify expected API calls happen with function matching

## Execution Steps

1. **Read the test file** to understand current structure

2. **Read and validate the resource definition**:

   - Find ALL attributes ending in `_id`
   - **Verify naming convention**: ALL Discord IDs MUST be `*_discord_id`, not
     `*_id`
     - ❌ BAD: `guild_id`, `user_id`, `channel_id`
     - ✅ GOOD: `guild_discord_id`, `user_discord_id`, `channel_discord_id`
     - **If wrong naming found**: Fix the attribute name in the resource
       definition
   - **Verify relationships exist**: EVERY `*_discord_id` attribute MUST have a
     matching `belongs_to` relationship
     - **Exception**: Polymorphic fields (like `target_discord_id` with a type
       indicator field)
     - **If missing relationship found**: Add the `belongs_to` relationship to
       the resource:
       ```elixir
       belongs_to :name, TestApp.Discord.ResourceName do
         source_attribute(:name_discord_id)
         destination_attribute(:discord_id)
         attribute_writable?(true)
       end
       ```
   - Identify required vs optional attributes
   - Identify identity fields (for upsert behavior)

3. **Research Nostrum API availability**:
   - Check if Nostrum.Api has endpoints to fetch this resource
   - Identify which related resource API calls need mocking
   - If yes, include API fallback tests
   - If no, skip API fallback pattern entirely
4. **Analyze patterns** - identify which quality improvements apply
5. **Create todo list** with specific refactoring tasks
6. **Apply refactorings systematically**:
   - Add module documentation
   - Add `use Mimic` if API mocking needed
   - Organize tests into describe blocks (struct-first, API fallback if
     applicable, upsert)
   - Create struct-first pattern tests with inline mocks
   - Add API fallback tests (if applicable) with inline Mimic.expect
   - Add upsert behavior tests with inline mocks (struct-first only)
   - Remove `Mimic.copy` from setup if present
   - Remove any helper functions - inline mocks instead
7. **Verify changes** - ensure tests still pass
8. **Mark tests with :fixed tag** - add `@tag :fixed` to all passing tests:
   - This tracks which tests have been fixed during cleanup
   - Only tests tagged with `:fixed` should be passing
   - Place tag immediately before each test definition
   - Example:
     ```elixir
     @tag :fixed
     test "creates resource from discord struct" do
     ```
9. **Commit with descriptive message** following the pattern:

   ```
   test: apply quality patterns to [resource] from_discord tests

   - Add comprehensive struct-first pattern tests
   - Add API fallback pattern tests (if applicable)
   - Test upsert behavior to prevent duplicates (struct-first only)
   - Mock related resource API calls instead of pre-creating records
   - Organize tests into clear describe blocks
   - Mark all passing tests with :fixed tag
   ```

10. **Run comprehensive review** - use `/review` command to verify:
    - All test patterns are correctly implemented
    - Mimic usage follows conventions (no copy in setup)
    - Upsert behavior is properly verified
    - API mocks cover all necessary related resources
    - All passing tests have :fixed tag

## Example Transformation

### Before

```elixir
defmodule AshDiscord.Changes.FromDiscord.GuildMemberTest do
  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  test "creates guild member from discord" do
    data = guild_member(%{user_id: 123, nick: "test"})

    {:ok, created} = TestApp.Discord.guild_member_from_discord(%{
      data: data,
      identity: %{guild_discord_id: 999}
    })

    assert created.user_discord_id == 123
    assert created.nick == "test"
  end
end
```

### After

```elixir
defmodule AshDiscord.Changes.FromDiscord.GuildMemberTest do
  @moduledoc """
  Comprehensive tests for GuildMember entity from_discord transformation.

  Tests struct-first pattern, API fallback pattern, and upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    test "creates guild member from discord struct with all attributes" do
      Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      member_struct =
        guild_member(%{
          user_id: 123_456_789,
          nick: "TestNick",
          joined_at: to_unix_ms("2023-01-15T10:30:00Z"),
          deaf: false,
          mute: false
        })

      result =
        TestApp.Discord.guild_member_from_discord(%{
          data: member_struct,
          identity: %{guild_discord_id: 555_666_777}
        })

      assert {:ok, created_member} = result
      assert created_member.user_discord_id == member_struct.user_id
      assert created_member.nick == member_struct.nick
      assert created_member.joined_at == ~U[2023-01-15 10:30:00Z]
      assert created_member.deaf == false
      assert created_member.mute == false
      assert created_member.guild_discord_id == 555_666_777
    end

    test "handles member without nickname" do
      Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      member_struct =
        guild_member(%{
          user_id: 987_654_321,
          nick: nil,
          joined_at: to_unix_ms("2023-02-20T15:45:00Z"),
          deaf: false,
          mute: false
        })

      result =
        TestApp.Discord.guild_member_from_discord(%{
          data: member_struct,
          identity: %{guild_discord_id: 555_666_777}
        })

      assert {:ok, created_member} = result
      assert created_member.user_discord_id == member_struct.user_id
      assert created_member.nick == nil
      assert created_member.joined_at == ~U[2023-02-20 15:45:00Z]
    end
  end

  describe "API fallback pattern" do
    test "fetches guild member from API when data not provided" do
      guild_id = 555_666_777
      user_id = 999_888_777

      Mimic.expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
        {:ok,
         guild_member(%{
           user_id: user_id,
           nick: "API_Fetched_Nick",
           joined_at: to_unix_ms("2023-06-15T10:00:00Z"),
           deaf: false,
           mute: true,
           roles: [123_456, 789_012]
         })}
      end)

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      result =
        TestApp.Discord.guild_member_from_discord(%{
          identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
        })

      assert {:ok, created_member} = result
      assert created_member.user_discord_id == user_id
      assert created_member.guild_discord_id == guild_id
      assert created_member.nick == "API_Fetched_Nick"
      assert created_member.mute == true
      assert created_member.deaf == false
      assert created_member.roles == [123_456, 789_012]
    end
  end

  describe "upsert behavior" do
    test "updates existing guild member instead of creating duplicate" do
      Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      user_id = 555_666_777
      guild_id = 111_222_333

      # Create initial member
      initial_struct =
        guild_member(%{
          user_id: user_id,
          nick: "OriginalNick",
          joined_at: to_unix_ms("2023-01-01T00:00:00Z"),
          deaf: false,
          mute: false
        })

      {:ok, original_member} =
        TestApp.Discord.guild_member_from_discord(%{
          data: initial_struct,
          identity: %{guild_discord_id: guild_id}
        })

      # Update same member with new data
      updated_struct =
        guild_member(%{
          user_id: user_id,
          nick: "UpdatedNick",
          joined_at: to_unix_ms("2023-01-01T00:00:00Z"),
          deaf: true,
          mute: true
        })

      {:ok, updated_member} =
        TestApp.Discord.guild_member_from_discord(%{
          data: updated_struct,
          identity: %{guild_discord_id: guild_id}
        })

      # Should be same record (same Ash ID)
      assert updated_member.id == original_member.id
      assert updated_member.user_discord_id == original_member.user_discord_id
      assert updated_member.guild_discord_id == original_member.guild_discord_id

      # But with updated attributes
      assert updated_member.nick == "UpdatedNick"
      assert updated_member.deaf == true
      assert updated_member.mute == true
    end
  end
end
```

## Notes

- Focus on one test file at a time for clarity
- Run tests after each major change to catch issues early
- **Never add `Mimic.copy` in setup** - it's already in test_helper.exs
- **Mock related resource API calls** instead of pre-creating records
- **Inline all mocks directly in tests** - no helper functions
- Test realistic scenarios with proper data relationships
- Verify upsert behavior to ensure no duplicate records are created
