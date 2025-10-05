# Interaction Payload & Generator Review

**Date**: 2025-10-05 **Payload**:
`lib/ash_discord/consumer/payloads/interaction.ex` **Generator**:
`test/support/generators/discord.ex` (lines 334-366) **Status**: ⚠️ **ISSUES
FOUND**

## Summary

**Payload Status**: ✅ CORRECT - All fields properly typed and documented
**Generator Status**: ⚠️ **MINOR ISSUES** - Missing some optional fields and
patterns

## Payload Analysis

### ✅ Correctly Implemented Fields

All 14 fields correctly typed and documented:

1. **id**: `:integer`, `allow_nil?: false` ✅
2. **application_id**: `:integer`, `allow_nil?: false` ✅
3. **type**: `:integer`, `allow_nil?: false` ✅
4. **data**: `:map`, `allow_nil?: true` ✅
   - Correctly optional (not present on ping interactions)
5. **guild_id**: `:integer` ✅
6. **channel_id**: `:integer` ✅
7. **channel**: `:map`, `allow_nil?: true` ✅
8. **member**: `:map`, `allow_nil?: true` ✅
   - Correctly optional (only in guild contexts)
9. **user**: `:map` ✅
10. **token**: `:string`, `allow_nil?: false` ✅
11. **version**: `:integer`, `allow_nil?: false` ✅
12. **message**: `:map` ✅
13. **locale**: `:string`, `allow_nil?: false` ✅
14. **guild_locale**: `:string`, `allow_nil?: true` ✅
    - Correctly optional (only in guilds)

**Compliance**: 100% - All fields match Discord API and Nostrum types

## Generator Analysis

### ✅ Correct Implementation

#### 1. Member Field - Properly Typed Struct ✅

**Location**: Lines 347-359 **Status**: ✅ EXCELLENT

The generator correctly creates a proper `Nostrum.Struct.Guild.Member` struct
(not a plain map):

```elixir
member: struct(Nostrum.Struct.Guild.Member, %{
  user_id: interaction_user.id,
  nick: nil,
  roles: [],
  joined_at: Faker.DateTime.backward(365),
  premium_since: nil,
  communication_disabled_until: nil,
  deaf: false,
  mute: false,
  pending: false,
  flags: 0
})
```

**Impact**: ✅ Tests will correctly exercise Member struct code paths

### ⚠️ Minor Issues

#### 2. Missing `channel` Field

**Severity**: 🟡 MEDIUM **Location**: Lines 337-363 **Issue**: Generator never
includes the optional `channel` field

**Discord Behavior**: Interactions in channels can include partial channel
objects

**Recommendation**:

```elixir
# Add channel field (optional partial channel object)
channel: if(Faker.Util.pick([true, false, false]), do: %{
  id: attrs[:channel_id] || generate_snowflake(),
  type: 0,
  name: Faker.Lorem.word()
}, else: nil),
```

#### 3. Missing `message` Field for Component Interactions

**Severity**: 🟡 MEDIUM **Location**: Lines 337-363 **Issue**: Generator never
includes `message` field

**Discord Behavior**: Message component interactions (type 3) always include the
message they were attached to

**Recommendation**:

```elixir
# For component interactions (type 3), add message field
message: if(attrs[:type] == 3, do: %{
  id: generate_snowflake(),
  channel_id: attrs[:channel_id] || generate_snowflake(),
  content: Faker.Lorem.sentence(1..10)
}, else: nil),
```

#### 4. Missing `locale` Field

**Severity**: 🟡 MEDIUM **Location**: Lines 337-363 **Issue**: Generator never
includes the required `locale` field

**Recommendation**:

```elixir
locale: Faker.Util.pick(["en-US", "en-GB", "fr", "de", "es-ES", "pt-BR", "ja", "zh-CN"]),
```

#### 5. Missing `guild_locale` Field

**Severity**: 🟡 MEDIUM **Location**: Lines 337-363 **Issue**: Generator never
includes optional `guild_locale` field

**Recommendation**:

```elixir
guild_locale: if(attrs[:guild_id], do: Faker.Util.pick(["en-US", "en-GB", "fr", "de"]), else: nil),
```

### ⚠️ Realism Issues

#### 6. Only Generates Application Command Interactions

**Severity**: 🟠 HIGH **Location**: Line 340 **Issue**: `type` always 2
(application command), never other interaction types

**Discord Interaction Types**:

- 1 = Ping
- 2 = Application Command
- 3 = Message Component
- 4 = Application Command Autocomplete
- 5 = Modal Submit

**Recommendation**:

```elixir
interaction_type = Faker.Util.pick([2, 2, 2, 3, 5])  # 60% commands, 20% components, 20% modals

# Adjust data based on type
data_value = case interaction_type do
  1 -> nil  # Ping has no data
  2 -> %{  # Application command
    name: Faker.Util.pick(["hello", "help", "ping", "info"]),
    options: []
  }
  3 -> %{  # Message component
    component_type: 2,  # Button
    custom_id: "button_#{Faker.UUID.v4()}"
  }
  4 -> %{  # Autocomplete
    name: "search",
    options: [%{name: "query", value: Faker.Lorem.word()}]
  }
  5 -> %{  # Modal submit
    custom_id: "modal_#{Faker.UUID.v4()}",
    components: []
  }
end

defaults = %{
  # ...
  type: interaction_type,
  data: data_value,
  # ...
}
```

#### 7. Never Generates DM Interactions

**Severity**: 🟡 MEDIUM **Location**: Line 345 **Issue**: `guild_id` always
present, never nil for DM interactions

**Recommendation**:

```elixir
# 20% DM interactions
has_guild = Faker.Util.pick([true, true, true, true, false])

defaults = %{
  # ...
  guild_id: if(has_guild, do: generate_snowflake(), else: nil),
  member: if(has_guild, do: struct(Nostrum.Struct.Guild.Member, %{...}), else: nil),
  guild_locale: if(has_guild, do: Faker.Util.pick(["en-US", "en-GB"]), else: nil),
  # ...
}
```

## Alignment Summary

### Type Alignment

| Field          | Payload Type  | Generator Type | Match            |
| -------------- | ------------- | -------------- | ---------------- |
| id             | :integer      | :integer       | ✅               |
| application_id | :integer      | :integer       | ✅               |
| type           | :integer      | :integer       | ⚠️ Only type 2   |
| data           | :map (nil)    | :map           | ⚠️ Never nil     |
| guild_id       | :integer      | :integer       | ⚠️ Never nil     |
| channel_id     | :integer      | :integer       | ✅               |
| channel        | :map (nil)    | -              | ❌ MISSING       |
| member         | :map (nil)    | Member struct  | ✅ Proper struct |
| user           | :map          | User struct    | ✅               |
| token          | :string       | :string        | ✅               |
| version        | :integer      | :integer       | ✅               |
| message        | :map          | -              | ❌ MISSING       |
| locale         | :string       | -              | ❌ MISSING       |
| guild_locale   | :string (nil) | -              | ❌ MISSING       |

**Overall Alignment**: 64% (9/14 fields correct)

## Critical Fixes Required

### Priority 1 (SHOULD FIX)

1. ❌ **Add `locale` field** - Required by payload, completely missing
2. ❌ **Add `guild_locale` field** - Optional but important for guild
   interactions
3. ❌ **Add `channel` field** - Optional partial channel object
4. ❌ **Add `message` field** - Required for component interactions

### Priority 2 (NICE TO HAVE)

5. ⚠️ **Support interaction type variation** - Generate ping, component, modal
   interactions
6. ⚠️ **Support DM interactions** - Set guild_id/member/guild_locale to nil for
   DMs

## Test Coverage Recommendations

### Essential Tests

```elixir
# Test guild interaction with member
interaction = Discord.interaction(%{guild_id: 123})
assert %Nostrum.Struct.Guild.Member{} = interaction.member
assert interaction.guild_locale != nil

# Test DM interaction without member
interaction = Discord.interaction(%{guild_id: nil})
assert is_nil(interaction.member)
assert is_nil(interaction.guild_locale)

# Test component interaction with message
interaction = Discord.interaction(%{type: 3})
assert interaction.message != nil

# Test locale fields
interaction = Discord.interaction()
assert is_binary(interaction.locale)
```

## Recommendations

1. **Immediate**: Add `locale`, `guild_locale`, `channel`, and `message` fields
2. **High Priority**: Support DM interactions (nil guild fields)
3. **Medium Priority**: Add interaction type variation (ping, component, modal)
4. **Consider**: Type-specific data patterns for different interaction types

## Conclusion

**Payload**: ✅ Fully compliant with Discord API and Nostrum types
**Generator**: ⚠️ Good foundation with proper Member struct, but missing several
fields

The Interaction payload is correctly implemented with all proper types and
nullability. The generator has the critical Member struct correct (using proper
Nostrum.Struct.Guild.Member), but is missing:

- Required `locale` field
- Optional `guild_locale`, `channel`, `message` fields
- Interaction type variation (only generates application commands)
- DM interaction patterns

**Action Required**: Add missing fields for comprehensive interaction testing,
especially locale fields and component interaction support.
