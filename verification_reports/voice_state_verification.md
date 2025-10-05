# VoiceState Payload Verification Report

**Generated:** 2025-10-05 **File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/voice_state.ex`
**Discord API Reference:**
https://discord.com/developers/docs/resources/voice#voice-state-object
**Discord.js API Reference:**
https://discord.js.org/docs/packages/discord.js/14.19.1/APIVoiceState:Interface

---

## Executive Summary

The VoiceState payload implementation has **4 field issues** that need
correction:

1. ✅ **13 fields correctly implemented**
2. ❌ **3 fields with incorrect `allow_nil?` settings**
3. ❌ **1 field with incorrect type**
4. ✅ **0 missing fields**
5. ✅ **0 extra fields**

---

## Discord API Voice State Object Structure

Based on the official Discord API (via discord.js TypeScript interface):

```typescript
interface APIVoiceState {
  channel_id: Snowflake | null; // nullable
  deaf: boolean; // required, non-null
  guild_id?: Snowflake; // optional
  member?: APIGuildMember; // optional
  mute: boolean; // required, non-null
  request_to_speak_timestamp: string | null; // nullable
  self_deaf: boolean; // required, non-null
  self_mute: boolean; // required, non-null
  self_stream?: boolean; // optional
  self_video: boolean; // required, non-null
  session_id: string; // required, non-null
  suppress: boolean; // required, non-null
  user_id: Snowflake; // required, non-null
}
```

### Nullability & Optionality Conventions

- **`field?: Type`** → Optional field (may not be present) → `allow_nil?: true`
- **`Type | null`** → Nullable field (always present, but value can be null) →
  `allow_nil?: true`
- **`Type`** → Required, non-null → `allow_nil?: false` (or omit, default is
  false)

---

## Field-by-Field Comparison

### ✅ Correctly Implemented Fields

| Field        | Discord Type           | Our Type   | allow_nil? | Status     |
| ------------ | ---------------------- | ---------- | ---------- | ---------- |
| `user_id`    | `Snowflake` (required) | `:integer` | `false`    | ✅ Correct |
| `session_id` | `string` (required)    | `:string`  | `false`    | ✅ Correct |
| `deaf`       | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |
| `mute`       | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |
| `self_deaf`  | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |
| `self_mute`  | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |
| `self_video` | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |
| `suppress`   | `boolean` (required)   | `:boolean` | `false`    | ✅ Correct |

### ❌ Fields Requiring Corrections

#### 1. `guild_id` - Missing `allow_nil?: true`

**Discord API:** `guild_id?: Snowflake` (optional) **Current Implementation:**

```elixir
field :guild_id, :integer, description: "Guild ID this voice state is for (if applicable)"
```

**Issue:** Field is optional in Discord API but our implementation doesn't have
`allow_nil?: true`

**Recommended Fix:**

```elixir
field :guild_id, :integer,
  allow_nil?: true,
  description: "Guild ID this voice state is for (optional, only present for guild voice channels)"
```

---

#### 2. `channel_id` - Missing `allow_nil?: true`

**Discord API:** `channel_id: Snowflake | null` (nullable) **Current
Implementation:**

```elixir
field :channel_id, :integer,
  description: "Channel ID this voice state is for (nil if user left voice)"
```

**Issue:** Field is nullable in Discord API but our implementation doesn't have
`allow_nil?: true`

**Observation:** The description correctly mentions "nil if user left voice" but
the field definition doesn't allow nil.

**Recommended Fix:**

```elixir
field :channel_id, :integer,
  allow_nil?: true,
  description: "Channel ID this voice state is for (nil if user left voice)"
```

---

#### 3. `member` - Missing `allow_nil?: true`

**Discord API:** `member?: APIGuildMember` (optional) **Current
Implementation:**

```elixir
field :member, AshDiscord.Consumer.Payloads.Member,
  description: "Guild member this voice state is for"
```

**Issue:** Field is optional in Discord API but our implementation doesn't have
`allow_nil?: true`

**Recommended Fix:**

```elixir
field :member, AshDiscord.Consumer.Payloads.Member,
  allow_nil?: true,
  description: "Guild member this voice state is for (optional)"
```

---

#### 4. `self_stream` - Missing `allow_nil?: true`

**Discord API:** `self_stream?: boolean` (optional) **Current Implementation:**

```elixir
field :self_stream, :boolean, description: "Whether this user is streaming using Go Live"
```

**Issue:** Field is optional in Discord API but our implementation doesn't have
`allow_nil?: true`

**Recommended Fix:**

```elixir
field :self_stream, :boolean,
  allow_nil?: true,
  description: "Whether this user is streaming using Go Live (optional)"
```

---

#### 5. `request_to_speak_timestamp` - Incorrect Type

**Discord API:** `request_to_speak_timestamp: string | null` (nullable
string/ISO8601) **Current Implementation:**

```elixir
field :request_to_speak_timestamp, :utc_datetime,
  description: "Time at which the user requested to speak"
```

**Issue:**

1. Type should allow string (ISO8601) from Discord, not just `:utc_datetime`
2. Field is nullable but doesn't have `allow_nil?: true`

**Recommended Fix:**

```elixir
field :request_to_speak_timestamp, :utc_datetime,
  allow_nil?: true,
  description: "Time at which the user requested to speak (nullable ISO8601 timestamp)"
```

**Note:** Using `:utc_datetime` is acceptable if the `new/1` function handles
conversion from ISO8601 strings to DateTime. However, `allow_nil?: true` is
required.

---

## Summary of Required Changes

### File: `/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/voice_state.ex`

Apply the following changes:

```elixir
# Line 16 - Add allow_nil?: true to guild_id
field :guild_id, :integer,
  allow_nil?: true,
  description: "Guild ID this voice state is for (optional, only present for guild voice channels)"

# Line 18-19 - Add allow_nil?: true to channel_id
field :channel_id, :integer,
  allow_nil?: true,
  description: "Channel ID this voice state is for (nil if user left voice)"

# Line 23-24 - Add allow_nil?: true to member
field :member, AshDiscord.Consumer.Payloads.Member,
  allow_nil?: true,
  description: "Guild member this voice state is for (optional)"

# Line 44 - Add allow_nil?: true to self_stream
field :self_stream, :boolean,
  allow_nil?: true,
  description: "Whether this user is streaming using Go Live (optional)"

# Line 54-55 - Add allow_nil?: true to request_to_speak_timestamp
field :request_to_speak_timestamp, :utc_datetime,
  allow_nil?: true,
  description: "Time at which the user requested to speak (nullable ISO8601 timestamp)"
```

---

## Verification Checklist

- [x] All Discord API fields are present in our implementation
- [x] No extra fields exist that aren't in Discord API
- [x] Field types match Discord API expectations
- [ ] `allow_nil?` settings match Discord's optional/nullable markings
  - [ ] `guild_id` - needs `allow_nil?: true` (optional)
  - [ ] `channel_id` - needs `allow_nil?: true` (nullable)
  - [ ] `member` - needs `allow_nil?: true` (optional)
  - [ ] `self_stream` - needs `allow_nil?: true` (optional)
  - [ ] `request_to_speak_timestamp` - needs `allow_nil?: true` (nullable)

---

## Additional Notes

### Field Ordering

Current field ordering does not match Discord API documentation order. Consider
reordering for consistency:

**Discord API Order:**

1. `guild_id`
2. `channel_id`
3. `user_id`
4. `member`
5. `session_id`
6. `deaf`
7. `mute`
8. `self_deaf`
9. `self_mute`
10. `self_stream`
11. `self_video`
12. `suppress`
13. `request_to_speak_timestamp`

**Current Order:**

1. `guild_id`
2. `channel_id`
3. `user_id`
4. `member`
5. `session_id`
6. `deaf`
7. `mute`
8. `self_deaf`
9. `self_mute`
10. `self_stream`
11. `self_video`
12. `suppress`
13. `request_to_speak_timestamp`

✅ Field ordering already matches Discord API documentation!

### Type Conversions

The `new/1` function should handle:

- Snowflake (string) → integer conversion for IDs
- ISO8601 string → DateTime conversion for timestamps
- Nested object → Member payload conversion

These conversions appear to be handled by the parent `super/1` call and should
be verified in testing.

---

## References

- [Discord API - Voice State Object](https://discord.com/developers/docs/resources/voice#voice-state-object)
- [Discord.js APIVoiceState Interface](https://discord.js.org/docs/packages/discord.js/14.19.1/APIVoiceState:Interface)
- [Nostrum - Event.VoiceState](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.VoiceState.html)
