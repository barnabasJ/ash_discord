# VoiceState Payload & Generator Review

**Date**: 2025-10-05 **Payload**:
`lib/ash_discord/consumer/payloads/voice_state.ex` **Generator**:
`test/support/generators/discord.ex` (lines 766-782) **Status**: ⚠️ **ISSUES
FOUND**

## Summary

**Payload Status**: ✅ CORRECT - All fields properly typed and documented
**Generator Status**: ❌ **CRITICAL ISSUES** - Missing fields and unrealistic
patterns

## Payload Analysis

### ✅ Correctly Implemented Fields

All 11 fields correctly typed and documented:

1. **guild_id**: `:integer`, `allow_nil?: true` ✅

   - Correctly optional (only present for guild voice channels)

2. **channel_id**: `:integer`, `allow_nil?: true` ✅

   - Correctly nullable (nil when user leaves voice)

3. **user_id**: `:integer`, `allow_nil?: false` ✅

   - Required field

4. **member**: `AshDiscord.Consumer.Payloads.Member`, `allow_nil?: true` ✅

   - Correctly optional

5. **session_id**: `:string`, `allow_nil?: false` ✅

   - Required field

6. **deaf**: `:boolean`, `allow_nil?: false` ✅
7. **mute**: `:boolean`, `allow_nil?: false` ✅
8. **self_deaf**: `:boolean`, `allow_nil?: false` ✅
9. **self_mute**: `:boolean`, `allow_nil?: false` ✅
10. **self_stream**: `:boolean`, `allow_nil?: true` ✅

    - Correctly optional (Go Live feature)

11. **self_video**: `:boolean`, `allow_nil?: false` ✅
12. **suppress**: `:boolean`, `allow_nil?: false` ✅
13. **request_to_speak_timestamp**: `:utc_datetime`, `allow_nil?: true` ✅
    - Correctly nullable

**Compliance**: 100% - All fields match Discord API and Nostrum types

## Generator Analysis

### ❌ Critical Issues

#### 1. Missing `member` Field (CRITICAL)

**Severity**: 🔴 CRITICAL **Location**: Lines 767-779 **Issue**: Generator never
includes the `member` field

```elixir
# Current (INCORRECT):
defaults = %{
  guild_id: generate_snowflake(),
  channel_id: generate_snowflake(),
  user_id: generate_snowflake(),
  session_id: Faker.UUID.v4(),
  # ... member field missing
}
```

**Impact**:

- VoiceState events in guilds always include member data
- Tests won't exercise member-related code paths
- Type mismatches when expecting Member struct

**Recommendation**:

```elixir
def voice_state(attrs \\ %{}) do
  voice_user = user()

  # 80% guild voice, 20% DM voice (Discord supports DM voice calls)
  has_guild = Faker.Util.pick([true, true, true, true, false])
  guild_id_value = if has_guild, do: generate_snowflake(), else: nil

  member_value = if has_guild do
    %Nostrum.Struct.Guild.Member{
      user_id: voice_user.id,
      nick: if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
      roles: [],
      joined_at: Faker.DateTime.backward(365),
      premium_since: if(Faker.Util.pick([true, false, false, false]),
        do: Faker.DateTime.backward(30), else: nil),
      communication_disabled_until: nil,
      deaf: false,
      mute: false,
      pending: false,
      flags: 0
    }
  else
    nil
  end

  defaults = %{
    guild_id: guild_id_value,
    channel_id: generate_snowflake(),  # Will handle disconnection separately
    user_id: voice_user.id,
    member: member_value,
    session_id: Faker.UUID.v4(),
    deaf: false,
    mute: false,
    self_deaf: Faker.Util.pick([true, false, false]),
    self_mute: Faker.Util.pick([true, false, false]),
    self_stream: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)),
      do: true, else: nil),  # 10% Go Live
    self_video: Faker.Util.pick([true, false, false, false]),  # 25% camera on
    suppress: false,
    request_to_speak_timestamp: nil  # Could add stage channel support later
  }

  struct(Nostrum.Struct.Event.VoiceState, merge_attrs(defaults, attrs))
end
```

#### 2. Missing `request_to_speak_timestamp` Field

**Severity**: 🟡 MEDIUM **Location**: Lines 767-779 **Issue**: Field completely
missing from generator

**Impact**: Stage channel features untested

**Recommendation**: Add to defaults (see code above, set to nil for now)

### ⚠️ Realism Issues

#### 3. Never Generates Disconnected States

**Severity**: 🟠 HIGH **Location**: Line 769 **Issue**: `channel_id` always has
a value, never nil

**Discord Behavior**: When a user leaves voice, Discord sends VoiceState with
`channel_id: nil`

**Recommendation**:

```elixir
# Support disconnection pattern (10% of voice states)
channel_id_value = if Faker.Util.pick(List.duplicate(true, 9) ++ [false]) do
  generate_snowflake()
else
  nil  # User disconnected from voice
end

defaults = %{
  # ...
  channel_id: channel_id_value,
  # ...
}
```

#### 4. Unrealistic `self_stream` Pattern

**Severity**: 🟡 MEDIUM **Location**: Line 776 **Issue**: Always `false`, never
uses Go Live feature

**Discord Behavior**: `self_stream` should be nil when not streaming, true when
streaming

**Current**:

```elixir
self_stream: false  # Wrong - should be nil or true
```

**Should be**:

```elixir
self_stream: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)),
  do: true, else: nil)  # 10% Go Live, 90% nil
```

#### 5. Never Generates Self-Deafened/Muted Users

**Severity**: 🟡 MEDIUM **Location**: Lines 773-774 **Issue**: `self_deaf` and
`self_mute` always false

**Recommendation**:

```elixir
self_deaf: Faker.Util.pick([true, false, false]),  # 33% self-deafened
self_mute: Faker.Util.pick([true, false, false]),  # 33% self-muted
```

## Alignment Summary

### Type Alignment

| Field                      | Payload Type        | Generator Type | Match             |
| -------------------------- | ------------------- | -------------- | ----------------- |
| guild_id                   | :integer (nil)      | :integer       | ❌ Never nil      |
| channel_id                 | :integer (nil)      | :integer       | ❌ Never nil      |
| user_id                    | :integer            | :integer       | ✅                |
| member                     | Member (nil)        | -              | ❌ MISSING        |
| session_id                 | :string             | :string        | ✅                |
| deaf                       | :boolean            | :boolean       | ✅                |
| mute                       | :boolean            | :boolean       | ✅                |
| self_deaf                  | :boolean            | :boolean       | ⚠️ Never true     |
| self_mute                  | :boolean            | :boolean       | ⚠️ Never true     |
| self_stream                | :boolean (nil)      | :boolean       | ❌ Never nil/true |
| self_video                 | :boolean            | :boolean       | ⚠️ Never true     |
| suppress                   | :boolean            | :boolean       | ✅                |
| request_to_speak_timestamp | :utc_datetime (nil) | -              | ❌ MISSING        |

**Overall Alignment**: 54% (7/13 fields correct)

## Critical Fixes Required

### Priority 1 (MUST FIX)

1. ❌ **Add `member` field** - Critical nested struct missing
2. ❌ **Add `request_to_speak_timestamp` field** - Missing payload field

### Priority 2 (SHOULD FIX)

3. ⚠️ **Support disconnection pattern** - `channel_id: nil` for 10% of states
4. ⚠️ **Fix `self_stream` pattern** - Use nil/true, not false
5. ⚠️ **Add self-deafen/mute variation** - Make these vary realistically

### Priority 3 (NICE TO HAVE)

6. 🟢 **Add video variation** - Some users have camera on
7. 🟢 **Consider stage channel support** - Add request_to_speak_timestamp
   patterns

## Test Coverage Recommendations

### Essential Tests

```elixir
# Test member field presence in guild voice
voice_state = Discord.voice_state(%{guild_id: 123})
assert %Nostrum.Struct.Guild.Member{} = voice_state.member

# Test member nil in DM voice
voice_state = Discord.voice_state(%{guild_id: nil})
assert is_nil(voice_state.member)

# Test disconnection (channel_id: nil)
voice_state = Discord.voice_state(%{channel_id: nil})
assert is_nil(voice_state.channel_id)

# Test Go Live (self_stream)
voice_state = Discord.voice_state(%{self_stream: true})
assert voice_state.self_stream == true

# Test stage channel (request_to_speak_timestamp)
voice_state = Discord.voice_state(%{request_to_speak_timestamp: ~U[2025-01-01 12:00:00Z]})
assert %DateTime{} = voice_state.request_to_speak_timestamp
```

## Recommendations

1. **Immediate**: Add `member` and `request_to_speak_timestamp` fields
2. **High Priority**: Fix `self_stream` nil/true pattern and support
   disconnection
3. **Medium Priority**: Add realistic variation to self-deafen/mute and video
4. **Consider**: Stage channel support with request_to_speak_timestamp patterns

## Conclusion

**Payload**: ✅ Fully compliant with Discord API and Nostrum types
**Generator**: ❌ Missing critical fields and realistic patterns

The VoiceState payload is correctly implemented with all proper types and
nullability. However, the generator has critical gaps:

- Missing `member` nested struct (breaks guild voice testing)
- Missing `request_to_speak_timestamp` field
- Never generates disconnected states (channel_id: nil)
- Incorrect `self_stream` pattern (uses false instead of nil/true)

**Action Required**: Implement Priority 1 fixes before considering VoiceState
testing complete.
