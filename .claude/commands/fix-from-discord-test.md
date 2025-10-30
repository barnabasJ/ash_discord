# Fix From Discord Test

Apply quality test patterns to fix a from_discord change test file.

## Command Behavior

When the user provides a test file path, analyze and refactor it using the
established quality patterns from GuildMember and User from_discord tests.

## Quality Test Patterns to Apply

### 1. Comprehensive Test Structure

Tests should cover four main areas:

- **struct-first pattern**: Creating from Discord data structs
- **API fallback pattern**: Creating from identity using Nostrum API (if
  applicable)
- **upsert behavior**: Verify updates instead of duplicates
- **error handling**: Invalid data, missing fields, API errors

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

### 3. Struct-First Pattern Tests

- Test creating resources from Discord struct data
- Use generators to create test data
- Inline mock related resource API calls at the start of each test
- Test various attribute combinations and edge cases
- No authorization bypass needed - these are action tests, not handler tests

Example:

```elixir
describe "struct-first pattern" do
  test "creates resource from discord struct with all attributes" do
    Mimic.expect(Nostrum.Api.User, :get, fn user_id ->
      {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
    end)

    resource_struct =
      resource(%{
        id: 123_456_789,
        user_id: 555_666_777,
        name: "Test Resource"
      })

    result = TestApp.Discord.resource_from_discord(%{data: resource_struct})

    assert {:ok, created} = result
    assert created.discord_id == resource_struct.id
    assert created.user_discord_id == 555_666_777
    assert created.name == resource_struct.name
  end

  test "handles nil optional field" do
    resource_struct = resource(%{id: 987_654_321, optional_field: nil})

    result = TestApp.Discord.resource_from_discord(%{data: resource_struct})

    assert {:ok, created} = result
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
- **DO NOT add `Mimic.copy` in setup** - it's already done in test_helper.exs
- Test both successful API calls and error handling

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

  test "handles API errors gracefully" do
    guild_id = 404_404_404
    user_id = 999_888_777

    Mimic.expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
      {:error, %{status_code: 404, message: "Unknown Guild"}}
    end)

    # API error short-circuits, so related resource API calls won't happen

    result =
      TestApp.Discord.resource_from_discord(%{
        identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
      })

    assert {:error, error} = result
    error_message = Exception.message(error)
    assert error_message =~ "Unknown Guild" or error_message =~ "404"
  end

  test "requires identity when no data provided" do
    result = TestApp.Discord.resource_from_discord(%{})

    assert {:error, _error} = result
  end
end
```

**Note**: Skip API fallback tests entirely if:

- No Nostrum API endpoint exists for fetching the resource
- The resource is only created through events, not fetchable directly

### 5. Upsert Behavior Tests

- Verify that calling `from_discord` twice with same identity updates the record
- Check that Ash ID remains the same (proves upsert, not duplicate creation)
- Test attribute updates work correctly
- Inline mock related resource API calls

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

### 6. Error Handling Tests

- Test invalid data formats
- Test missing required fields
- Test API errors (if API fallback applicable)
- Verify error messages are informative

Example:

```elixir
describe "error handling" do
  test "handles invalid data format" do
    result = TestApp.Discord.resource_from_discord(%{data: "not_a_struct"})

    assert {:error, error} = result
    error_message = Exception.message(error)
    assert error_message =~ "Invalid" or error_message =~ "is invalid"
  end

  test "handles missing required fields in data" do
    invalid_struct = resource(%{id: nil, name: nil})

    result = TestApp.Discord.resource_from_discord(%{data: invalid_struct})

    assert {:error, error} = result
    error_message = Exception.message(error)
    assert error_message =~ "required" or error_message =~ "invalid"
  end
end
```

### 7. Test Organization

- Group tests by behavior using `describe` blocks
- Use clear, descriptive test names
- Add module documentation explaining what's being tested
- Add `use Mimic` at module level if any tests need mocking
- Inline all mocks directly in tests - no helper functions

### 8. Mimic Setup

- **DO NOT add `Mimic.copy` calls** - already handled in test_helper.exs
- Only add `use Mimic` at module level if testing needs mocking
- Inline `Mimic.expect` calls at the start of each test
- Verify expected API calls happen with function matching

## Execution Steps

1. **Read the test file** to understand current structure
2. **Read the resource definition** to identify:
   - Required vs optional attributes
   - Foreign key relationships (to know which API calls to mock)
   - Identity fields (for upsert behavior)
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
   - Organize tests into describe blocks (struct-first, API fallback, upsert,
     error handling)
   - Create struct-first pattern tests with inline mocks
   - Add API fallback tests (if applicable) with inline Mimic.expect
   - Add upsert behavior tests with inline mocks
   - Add error handling tests
   - Remove `Mimic.copy` from setup if present
   - Remove any helper functions - inline mocks instead
7. **Verify changes** - ensure tests still pass
8. **Commit with descriptive message** following the pattern:

   ```
   test: apply quality patterns to [resource] from_discord tests

   - Add comprehensive struct-first pattern tests
   - Add API fallback pattern tests with mocked Nostrum calls
   - Test upsert behavior to prevent duplicates
   - Add error handling for invalid data and API failures
   - Mock related resource API calls instead of pre-creating records
   - Organize tests into clear describe blocks
   ```

9. **Run comprehensive review** - use `/review` command to verify:
   - All test patterns are correctly implemented
   - Mimic usage follows conventions (no copy in setup)
   - Tests cover both data and identity creation paths
   - Upsert behavior is properly verified
   - Error cases are handled appropriately
   - API mocks cover all necessary related resources

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

  Tests both struct-first and API fallback patterns, plus upsert behavior.
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

    test "handles API errors gracefully" do
      guild_id = 404_404_404
      user_id = 999_888_777

      Mimic.expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
        {:error, %{status_code: 404, message: "Unknown Guild"}}
      end)

      result =
        TestApp.Discord.guild_member_from_discord(%{
          identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
        })

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Unknown Guild" or error_message =~ "404"
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

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.guild_member_from_discord(%{data: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for data"
    end

    test "handles missing required fields in discord_struct" do
      invalid_struct = guild_member(%{user_id: nil})

      result =
        TestApp.Discord.guild_member_from_discord(%{
          data: invalid_struct,
          identity: %{guild_discord_id: 555_666_777}
        })

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "cannot be nil"
    end
  end
end
```

## Notes

- Focus on one test file at a time for clarity
- Run tests after each major change to catch issues early
- **Check Nostrum.Api documentation** to determine if API fallback is applicable
- If no API endpoint exists, skip API fallback tests entirely
- **Never add `Mimic.copy` in setup** - it's already in test_helper.exs
- **Mock related resource API calls** instead of pre-creating records
- **Inline all mocks directly in tests** - no helper functions
- Test realistic scenarios with proper data relationships
- Verify upsert behavior to ensure no duplicate records are created
