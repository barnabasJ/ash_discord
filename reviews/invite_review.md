# Invite Payload & Generator Review

**Date**: 2025-10-05 **Payload**: `lib/ash_discord/consumer/payloads/invite.ex`
**Generator**: `test/support/generators/discord.ex` (lines 589-604) **Status**:
⚠️ **ISSUES FOUND**

## Summary

**Payload Status**: ✅ CORRECT - All fields properly typed and documented
**Generator Status**: ❌ **CRITICAL ISSUES** - Missing many fields and incorrect
types

## Payload Analysis

### ✅ Correctly Implemented Fields

All 19 fields correctly typed and documented:

1. **code**: `:string`, `allow_nil?: false` ✅
2. **guild**: `:map`, `allow_nil?: true` ✅
3. **guild_id**: `:integer`, `allow_nil?: true` ✅
4. **channel**: `:map`, `allow_nil?: true` ✅
5. **channel_id**: `:integer`, `allow_nil?: true` ✅
6. **inviter**: `:map`, `allow_nil?: true` ✅
7. **target_user**: `:map`, `allow_nil?: true` ✅
8. **target_type**: `:integer`, `allow_nil?: true` ✅
9. **target_user_type**: `:integer`, `allow_nil?: true` ✅ (deprecated)
10. **approximate_presence_count**: `:integer` ✅
11. **approximate_member_count**: `:integer` ✅
12. **uses**: `:integer` ✅
13. **max_uses**: `:integer` ✅
14. **max_age**: `:integer` ✅
15. **temporary**: `:boolean` ✅
16. **created_at**: `:string` ✅
17. **expires_at**: `:string`, `allow_nil?: true` ✅
18. **stage_instance**: `:map` ✅
19. **guild_scheduled_event**: `:map` ✅

**Compliance**: 100% - All fields match Discord API and Nostrum types

## Generator Analysis

### ❌ Critical Issues

#### 1. Missing 11 Required/Optional Fields (CRITICAL)

**Severity**: 🔴 CRITICAL **Location**: Lines 592-601 **Issue**: Generator only
provides 8 of 19 fields

**Missing Fields**:

- `guild_id` - Integer (event-based invites)
- `channel_id` - Integer (event-based invites)
- `target_type` - Integer (stream/embedded application invites)
- `target_user_type` - Integer (deprecated but in payload)
- `approximate_presence_count` - Integer (extended invites)
- `approximate_member_count` - Integer (extended invites)
- `max_age` - Integer (invite expiration duration)
- `temporary` - Boolean (temporary membership flag)
- `created_at` - String (ISO8601 timestamp)
- `stage_instance` - Map (stage channel invites)
- `guild_scheduled_event` - Map (event invites)

**Current (INCOMPLETE)**:

```elixir
defaults = %{
  code: code,
  guild: guild(),
  channel: channel(),
  inviter: user(),
  target_user: nil,
  expires_at: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
  max_uses: 0,
  uses: 0
}
```

#### 2. Wrong Type for Guild and Channel (CRITICAL)

**Severity**: 🔴 CRITICAL **Location**: Lines 594-595 **Issue**: Generator
creates full structs instead of partial objects

**Discord Behavior**: Invite objects contain partial guild/channel objects
(subset of fields), not full structs

**Current (INCORRECT)**:

```elixir
guild: guild(),  # Full Guild struct
channel: channel(),  # Full Channel struct
```

**Should be (Partial Objects)**:

```elixir
guild: %{
  id: generate_snowflake(),
  name: Faker.Company.name(),
  splash: nil,
  banner: nil,
  description: nil,
  icon: nil,
  features: [],
  verification_level: 0,
  vanity_url_code: nil
},
channel: %{
  id: generate_snowflake(),
  name: Faker.Lorem.word(),
  type: Faker.Util.pick([0, 2, 5, 13, 15])  # Text, voice, announcement, stage, forum
}
```

### ⚠️ Realism Issues

#### 3. Always Includes Guild and Channel

**Severity**: 🟠 HIGH **Location**: Lines 594-595 **Issue**: `guild` and
`channel` always present, never nil

**Discord Behavior**: Simple invites may omit these (use guild_id/channel_id
instead)

**Recommendation**:

```elixir
# 80% full objects, 20% use IDs only
has_objects = Faker.Util.pick([true, true, true, true, false])

guild_value = if has_objects do
  %{id: generate_snowflake(), name: Faker.Company.name(), icon: nil}
else
  nil
end

guild_id_value = if not has_objects, do: generate_snowflake(), else: nil
```

#### 4. Never Generates Stream/App Invites

**Severity**: 🟡 MEDIUM **Location**: Line 597 **Issue**: `target_user` always
nil, never generates stream/embedded app invites

**Discord Behavior**: Invites can target users for streams or embedded
applications

**Recommendation**:

```elixir
# 10% have target_user and target_type
has_target = Faker.Util.pick([true] ++ List.duplicate(false, 9))

target_user: if has_target, do: user(), else: nil
target_type: if has_target, do: Faker.Util.pick([1, 2]), else: nil  # 1=stream, 2=embedded_app
```

#### 5. Never Generates Extended Invite Data

**Severity**: 🟡 MEDIUM **Location**: Lines 592-601 **Issue**: Missing
presence/member counts for extended invites

**Discord Behavior**: Invites with `with_counts=true` include approximate counts

**Recommendation**:

```elixir
# 50% extended invites with counts
has_counts = Faker.Util.pick([true, false])

approximate_presence_count: if has_counts, do: Faker.random_between(10, 1000), else: nil
approximate_member_count: if has_counts, do: Faker.random_between(100, 10000), else: nil
```

## Alignment Summary

### Type Alignment

| Field                      | Payload Type   | Generator Type | Match                       |
| -------------------------- | -------------- | -------------- | --------------------------- |
| code                       | :string        | :string        | ✅                          |
| guild                      | :map (nil)     | Guild struct   | ❌ Full struct, not partial |
| guild_id                   | :integer (nil) | -              | ❌ MISSING                  |
| channel                    | :map (nil)     | Channel struct | ❌ Full struct, not partial |
| channel_id                 | :integer (nil) | -              | ❌ MISSING                  |
| inviter                    | :map (nil)     | User struct    | ⚠️ Should be partial        |
| target_user                | :map (nil)     | nil            | ⚠️ Never populated          |
| target_type                | :integer (nil) | -              | ❌ MISSING                  |
| target_user_type           | :integer (nil) | -              | ❌ MISSING                  |
| approximate_presence_count | :integer       | -              | ❌ MISSING                  |
| approximate_member_count   | :integer       | -              | ❌ MISSING                  |
| uses                       | :integer       | :integer       | ✅                          |
| max_uses                   | :integer       | :integer       | ✅                          |
| max_age                    | :integer       | -              | ❌ MISSING                  |
| temporary                  | :boolean       | -              | ❌ MISSING                  |
| created_at                 | :string        | -              | ❌ MISSING                  |
| expires_at                 | :string (nil)  | :string        | ✅                          |
| stage_instance             | :map           | -              | ❌ MISSING                  |
| guild_scheduled_event      | :map           | -              | ❌ MISSING                  |

**Overall Alignment**: 21% (4/19 fields correct)

## Critical Fixes Required

### Priority 1 (MUST FIX)

1. ❌ **Fix guild/channel to partial objects** - Currently full structs
2. ❌ **Add guild_id and channel_id** - Support event-based invites
3. ❌ **Add max_age field** - Required invite metadata
4. ❌ **Add temporary field** - Required invite metadata
5. ❌ **Add created_at field** - Required invite metadata

### Priority 2 (SHOULD FIX)

6. ❌ **Add approximate_presence_count** - Extended invite data
7. ❌ **Add approximate_member_count** - Extended invite data
8. ❌ **Add target_type** - Stream/app invite support
9. ⚠️ **Support target_user patterns** - Generate stream/app invites

### Priority 3 (NICE TO HAVE)

10. ❌ **Add stage_instance** - Stage channel invites
11. ❌ **Add guild_scheduled_event** - Event invites

## Recommended Implementation

```elixir
def invite(attrs \\ %{}) do
  code = Faker.Lorem.characters(6..10) |> to_string() |> String.replace(~r/[^a-zA-Z0-9]/, "")

  # 80% partial objects, 20% IDs only
  has_objects = Faker.Util.pick([true, true, true, true, false])

  # 50% extended invites with counts
  has_counts = Faker.Util.pick([true, false])

  # 10% target invites (stream/embedded app)
  has_target = Faker.Util.pick([true] ++ List.duplicate(false, 9))

  # 5% event invites
  has_event = Faker.Util.pick([true] ++ List.duplicate(false, 19))

  guild_id_value = generate_snowflake()
  channel_id_value = generate_snowflake()

  defaults = %{
    code: code,
    guild: if has_objects do
      %{
        id: guild_id_value,
        name: Faker.Company.name(),
        splash: nil,
        banner: nil,
        description: nil,
        icon: nil,
        features: [],
        verification_level: 0,
        vanity_url_code: nil
      }
    else
      nil
    end,
    guild_id: if not has_objects, do: guild_id_value, else: nil,
    channel: if has_objects do
      %{
        id: channel_id_value,
        name: Faker.Lorem.word(),
        type: Faker.Util.pick([0, 2, 5, 13, 15])
      }
    else
      nil
    end,
    channel_id: if not has_objects, do: channel_id_value, else: nil,
    inviter: %{
      id: generate_snowflake(),
      username: Faker.Internet.user_name(),
      discriminator: "0",
      avatar: nil
    },
    target_user: if has_target, do: %{
      id: generate_snowflake(),
      username: Faker.Internet.user_name(),
      discriminator: "0",
      avatar: nil
    }, else: nil,
    target_type: if has_target, do: Faker.Util.pick([1, 2]), else: nil,
    target_user_type: nil,  # Deprecated
    approximate_presence_count: if has_counts, do: Faker.random_between(10, 1000), else: nil,
    approximate_member_count: if has_counts, do: Faker.random_between(100, 10000), else: nil,
    uses: Faker.random_between(0, 100),
    max_uses: Faker.Util.pick([0, 10, 25, 50, 100]),
    max_age: Faker.Util.pick([0, 1800, 3600, 86400, 604800]),  # 0, 30min, 1hr, 1day, 1week
    temporary: Faker.Util.pick([true, false, false]),  # 33% temporary
    created_at: Faker.DateTime.backward(30) |> DateTime.to_iso8601(),
    expires_at: if(Faker.Util.pick([true, false, false]),
      do: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
      else: nil),
    stage_instance: nil,  # Could add stage support later
    guild_scheduled_event: if has_event do
      %{
        id: generate_snowflake(),
        name: Faker.Lorem.sentence(1..5),
        description: Faker.Lorem.sentence(5..20)
      }
    else
      nil
    end
  }

  struct(Nostrum.Struct.Invite, merge_attrs(defaults, attrs))
end
```

## Test Coverage Recommendations

### Essential Tests

```elixir
# Test partial objects vs IDs
invite = Discord.invite(%{guild: nil, guild_id: 123})
assert invite.guild == nil
assert invite.guild_id == 123

# Test extended invite with counts
invite = Discord.invite(%{approximate_presence_count: 500})
assert invite.approximate_presence_count == 500

# Test target invites
invite = Discord.invite(%{target_user: user, target_type: 1})
assert %{} = invite.target_user
assert invite.target_type == 1

# Test invite metadata
invite = Discord.invite()
assert is_binary(invite.created_at)
assert is_integer(invite.max_age)
assert is_boolean(invite.temporary)

# Test event invites
invite = Discord.invite(%{guild_scheduled_event: %{id: 123}})
assert invite.guild_scheduled_event.id == 123
```

## Recommendations

1. **Immediate**: Fix guild/channel to partial objects, add missing required
   fields (guild_id, channel_id, max_age, temporary, created_at)
2. **High Priority**: Add extended invite fields (counts)
3. **Medium Priority**: Add target invite support (target_user, target_type)
4. **Consider**: Event and stage instance support

## Conclusion

**Payload**: ✅ Fully compliant with Discord API and Nostrum types
**Generator**: ❌ Severely incomplete with only 21% field coverage

The Invite payload is correctly implemented with all proper types and
nullability. However, the generator has major gaps:

- Only 8 of 19 fields implemented
- Incorrect types for guild/channel (full structs instead of partial objects)
- Missing critical metadata fields (max_age, temporary, created_at)
- No support for extended invites, target invites, or event invites

**Action Required**: Complete rewrite of generator to include all fields and
correct types for comprehensive invite testing.
