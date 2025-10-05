# AutoModerationRule Payload & Generator Review

**Date**: 2025-10-05 **Payload**:
`lib/ash_discord/consumer/payloads/auto_moderation_rule.ex` **Generator**:
`test/support/generators/discord.ex` (lines 1272-1297) **Status**: ⚠️ **ISSUES
FOUND**

## Summary

**Payload Status**: ✅ CORRECT - All fields properly typed and documented
**Generator Status**: ⚠️ **MINOR ISSUES** - Missing some variation and edge
cases

## Payload Analysis

### ✅ Correctly Implemented Fields

All 11 fields correctly typed and documented:

1. **id**: `:integer`, `allow_nil?: false` ✅
2. **guild_id**: `:integer`, `allow_nil?: false` ✅
3. **name**: `:string`, `allow_nil?: false` ✅
4. **creator_id**: `:integer`, `allow_nil?: false` ✅
5. **event_type**: `:integer`, `allow_nil?: false` ✅
6. **trigger_type**: `:integer`, `allow_nil?: false` ✅
7. **trigger_metadata**: `:map`, `allow_nil?: true` ✅
8. **actions**: `{:array, :map}`, `allow_nil?: false` ✅
9. **enabled**: `:boolean`, `allow_nil?: false` ✅
10. **exempt_roles**: `{:array, :integer}`, `allow_nil?: true` ✅
11. **exempt_channels**: `{:array, :integer}`, `allow_nil?: true` ✅

**Compliance**: 100% - All fields match Discord API and Nostrum types

## Generator Analysis

### ✅ Correct Implementation

#### 1. Basic Structure - Properly Implemented ✅

**Location**: Lines 1273-1294 **Status**: ✅ GOOD

The generator correctly creates all required fields with appropriate types:

- Integer IDs (snowflakes)
- String name
- Integer enums for event_type and trigger_type
- Map for trigger_metadata
- Array of maps for actions
- Boolean for enabled
- Arrays of integers for exempt lists

### ⚠️ Minor Issues

#### 2. Only Generates Keyword Filter Type

**Severity**: 🟡 MEDIUM **Location**: Lines 1278-1282 **Issue**: `trigger_type`
always 1 (keyword), never other trigger types

**Discord Auto-Moderation Trigger Types**:

- 1 = Keyword
- 3 = Spam
- 4 = Keyword Preset
- 5 = Mention Spam
- 6 = Member Profile

**Current (LIMITED)**:

```elixir
event_type: 1,  # Always MESSAGE_SEND
trigger_type: 1,  # Always KEYWORD
trigger_metadata: %{
  keyword_filter: ["spam", "badword"]
}
```

**Recommendation**:

```elixir
trigger_type_val = Faker.Util.pick([1, 3, 4, 5])  # Vary trigger types

trigger_metadata_val = case trigger_type_val do
  1 -> %{keyword_filter: ["spam", "badword", "scam"]}  # Keyword
  3 -> nil  # Spam detection has no metadata
  4 -> %{presets: [1, 2]}  # Keyword preset: profanity, sexual content
  5 -> %{mention_total_limit: Faker.random_between(3, 10)}  # Mention spam
  6 -> %{keyword_filter: ["18+", "NSFW"]}  # Member profile keywords
end

defaults = %{
  # ...
  trigger_type: trigger_type_val,
  trigger_metadata: trigger_metadata_val,
  # ...
}
```

#### 3. Only Generates One Action Type

**Severity**: 🟡 MEDIUM **Location**: Lines 1283-1289 **Issue**: `actions`
always type 1 (block message), never other action types

**Discord Auto-Moderation Action Types**:

- 1 = Block Message
- 2 = Send Alert Message
- 3 = Timeout

**Recommendation**:

```elixir
actions_val = [
  # Primary action
  case Faker.Util.pick([1, 2, 3]) do
    1 -> %{type: 1}  # Block message (no metadata)
    2 -> %{type: 2, metadata: %{channel_id: generate_snowflake()}}  # Send alert
    3 -> %{type: 3, metadata: %{duration_seconds: Faker.Util.pick([60, 300, 600, 3600])}}  # Timeout
  end
]

# 30% chance of second action (e.g., block + alert)
actions_val = if Faker.Util.pick([true, false, false]) do
  actions_val ++ [%{type: 2, metadata: %{channel_id: generate_snowflake()}}]
else
  actions_val
end
```

#### 4. Never Generates Disabled Rules

**Severity**: 🟡 MEDIUM **Location**: Line 1291 **Issue**: `enabled` always
true, never generates disabled rules

**Recommendation**:

```elixir
enabled: Faker.Util.pick([true, true, true, true, false])  # 80% enabled, 20% disabled
```

#### 5. Always Empty Exemption Lists

**Severity**: 🟡 MEDIUM **Location**: Lines 1292-1293 **Issue**: `exempt_roles`
and `exempt_channels` always empty

**Discord Behavior**: Rules often exempt moderator roles or specific channels

**Recommendation**:

```elixir
# 40% have exempt roles (moderators, admins)
exempt_roles: if Faker.Util.pick([true, false]) do
  Enum.map(1..Faker.random_between(1, 3), fn _ -> generate_snowflake() end)
else
  []
end,

# 30% have exempt channels (admin channels, bot channels)
exempt_channels: if Faker.Util.pick([true, false, false]) do
  Enum.map(1..Faker.random_between(1, 2), fn _ -> generate_snowflake() end)
else
  []
end
```

#### 6. Missing Trigger Metadata Nil Pattern

**Severity**: 🟡 MEDIUM **Location**: Lines 1280-1282 **Issue**:
`trigger_metadata` always has a value, never nil

**Discord Behavior**: Spam detection (type 3) has no metadata (nil)

**Already covered in recommendation #2** (trigger_metadata set to nil for spam
type)

## Alignment Summary

### Type Alignment

| Field            | Payload Type             | Generator Type     | Match                 |
| ---------------- | ------------------------ | ------------------ | --------------------- |
| id               | :integer                 | :integer           | ✅                    |
| guild_id         | :integer                 | :integer           | ✅                    |
| name             | :string                  | :string            | ✅                    |
| creator_id       | :integer                 | :integer           | ✅                    |
| event_type       | :integer                 | :integer           | ✅                    |
| trigger_type     | :integer                 | :integer           | ⚠️ Only type 1        |
| trigger_metadata | :map (nil)               | :map               | ⚠️ Never nil          |
| actions          | {:array, :map}           | {:array, :map}     | ⚠️ Only type 1 action |
| enabled          | :boolean                 | :boolean           | ⚠️ Always true        |
| exempt_roles     | {:array, :integer} (nil) | {:array, :integer} | ⚠️ Always empty       |
| exempt_channels  | {:array, :integer} (nil) | {:array, :integer} | ⚠️ Always empty       |

**Overall Alignment**: 55% (6/11 fields fully correct, 5 need variation)

## Critical Fixes Required

### Priority 1 (SHOULD FIX)

1. ⚠️ **Add trigger type variation** - Support spam, keyword preset, mention
   spam, member profile types
2. ⚠️ **Add action type variation** - Support block, alert, and timeout actions
3. ⚠️ **Support trigger_metadata nil** - For spam detection type

### Priority 2 (NICE TO HAVE)

4. ⚠️ **Add disabled rule pattern** - 20% disabled rules
5. ⚠️ **Populate exemption lists** - Add exempt roles and channels
6. 🟢 **Add multiple actions** - Some rules have 2+ actions

## Recommended Implementation

```elixir
def auto_moderation_rule(attrs \\ %{}) do
  # Vary trigger types
  trigger_type_val = Faker.Util.pick([1, 1, 3, 4, 5])  # 40% keyword, 20% each other

  trigger_metadata_val = case trigger_type_val do
    1 -> %{keyword_filter: Faker.Util.pick([
      ["spam", "scam", "phishing"],
      ["badword", "slur"],
      ["18+", "NSFW", "porn"]
    ])}
    3 -> nil  # Spam has no metadata
    4 -> %{presets: Faker.Util.pick([[1], [2], [1, 2]])}  # Profanity/sexual presets
    5 -> %{mention_total_limit: Faker.random_between(3, 10)}
    6 -> %{keyword_filter: ["18+", "NSFW"]}  # Member profile
  end

  # Primary action
  primary_action = case Faker.Util.pick([1, 2, 3]) do
    1 -> %{type: 1}  # Block
    2 -> %{type: 2, metadata: %{channel_id: generate_snowflake()}}  # Alert
    3 -> %{type: 3, metadata: %{duration_seconds: Faker.Util.pick([60, 300, 3600])}}  # Timeout
  end

  # 30% chance of secondary action (alert)
  actions_val = if Faker.Util.pick([true, false, false]) and primary_action.type != 2 do
    [primary_action, %{type: 2, metadata: %{channel_id: generate_snowflake()}}]
  else
    [primary_action]
  end

  defaults = %{
    id: generate_snowflake(),
    guild_id: generate_snowflake(),
    name: Faker.Lorem.words(2..3) |> Enum.join(" "),
    creator_id: generate_snowflake(),
    event_type: 1,  # MESSAGE_SEND is the main type
    trigger_type: trigger_type_val,
    trigger_metadata: trigger_metadata_val,
    actions: actions_val,
    enabled: Faker.Util.pick([true, true, true, true, false]),  # 80% enabled
    exempt_roles: if Faker.Util.pick([true, false]) do
      Enum.map(1..Faker.random_between(1, 3), fn _ -> generate_snowflake() end)
    else
      []
    end,
    exempt_channels: if Faker.Util.pick([true, false, false]) do
      Enum.map(1..Faker.random_between(1, 2), fn _ -> generate_snowflake() end)
    else
      []
    end
  }

  struct(Nostrum.Struct.AutoModerationRule, merge_attrs(defaults, attrs))
end
```

## Test Coverage Recommendations

### Essential Tests

```elixir
# Test keyword trigger with metadata
rule = Discord.auto_moderation_rule(%{trigger_type: 1})
assert rule.trigger_metadata.keyword_filter != nil

# Test spam trigger with nil metadata
rule = Discord.auto_moderation_rule(%{trigger_type: 3})
assert rule.trigger_metadata == nil

# Test mention spam trigger
rule = Discord.auto_moderation_rule(%{trigger_type: 5})
assert is_integer(rule.trigger_metadata.mention_total_limit)

# Test different action types
rule = Discord.auto_moderation_rule(%{actions: [%{type: 2, metadata: %{channel_id: 123}}]})
assert [%{type: 2}] = rule.actions

# Test disabled rule
rule = Discord.auto_moderation_rule(%{enabled: false})
assert rule.enabled == false

# Test exemptions
rule = Discord.auto_moderation_rule(%{exempt_roles: [123, 456]})
assert [123, 456] = rule.exempt_roles
```

## Recommendations

1. **Immediate**: Add trigger type variation with appropriate metadata patterns
2. **High Priority**: Add action type variation (block, alert, timeout)
3. **Medium Priority**: Support disabled rules and exemption lists
4. **Consider**: Multiple actions per rule (block + alert pattern)

## Conclusion

**Payload**: ✅ Fully compliant with Discord API and Nostrum types
**Generator**: ⚠️ Good foundation but limited variation

The AutoModerationRule payload is correctly implemented with all proper types
and nullability. The generator has a solid foundation with all fields present,
but lacks variation:

- Only generates keyword triggers (should support spam, presets, mention spam,
  member profile)
- Only generates block message actions (should support alerts and timeouts)
- Never generates disabled rules
- Never populates exemption lists
- Missing nil pattern for trigger_metadata (spam type)

**Action Required**: Add variation to trigger types, actions, and exemption
patterns for comprehensive auto-moderation testing.
