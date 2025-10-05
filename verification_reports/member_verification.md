# Member Payload Verification Report

**Date**: 2025-10-05 **File**:
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/member.ex`
**API Reference**: Discord API v10 (via discord-api-types)

## Summary

This report compares the AshDiscord Member payload implementation against the
official Discord API v10 Guild Member Object structure AND verified against
Nostrum's actual implementation.

**Status**: ❌ **2 Critical Type Mismatches Found**

**Critical Issues (Must Fix)**:

- `premium_since`: Type is `:integer` but Nostrum provides `DateTime.t()` - will
  cause runtime errors
- `communication_disabled_until`: Type is `:integer` but Nostrum provides
  `DateTime.t()` - will cause runtime errors

**Everything Else**:

- ✅ Most fields are correct (user_id, roles, joined_at, nick, avatar, deaf,
  mute, pending, flags)
- ⚠️ Optional: Update descriptions for clarity (roles, joined_at)
- ℹ️ Two Discord API v10 fields not yet in Nostrum (banner,
  avatar_decoration_data) - do NOT add until Nostrum supports them

**Action Required**: Change `premium_since` and `communication_disabled_until`
from `:integer` to `:datetime` type

---

## Discord API v10 Guild Member Object Structure

According to the official Discord API (via discord-api-types v10), the Guild
Member Object has the following fields:

| Field                          | Type                           | Optional | Nullable | Description                                                                       |
| ------------------------------ | ------------------------------ | -------- | -------- | --------------------------------------------------------------------------------- |
| `user`                         | APIUser object                 | No       | No       | The user this guild member represents                                             |
| `nick`                         | string                         | Yes      | Yes      | This user's guild nickname                                                        |
| `avatar`                       | string                         | Yes      | Yes      | The member's guild avatar hash                                                    |
| `banner`                       | string                         | Yes      | Yes      | The member's guild banner hash                                                    |
| `roles`                        | array of strings               | No       | No       | Array of role object ids                                                          |
| `joined_at`                    | string (ISO8601)               | No       | Yes      | When the user joined the guild                                                    |
| `premium_since`                | string (ISO8601)               | Yes      | Yes      | When the user started boosting the guild                                          |
| `deaf`                         | boolean                        | No       | No       | Whether the user is deafened in voice channels                                    |
| `mute`                         | boolean                        | No       | No       | Whether the user is muted in voice channels                                       |
| `flags`                        | integer (GuildMemberFlags)     | No       | No       | Guild member flags represented as a bit set                                       |
| `pending`                      | boolean                        | Yes      | No       | Whether the user has not yet passed the guild's Membership Screening requirements |
| `communication_disabled_until` | string (ISO8601)               | Yes      | Yes      | When the timeout will be removed; null or past time if not timed out              |
| `avatar_decoration_data`       | APIAvatarDecorationData object | Yes      | Yes      | The data for the member's guild avatar decoration                                 |

---

## CRITICAL FINDING - DateTime Type Mismatch ⚠️

**URGENT**: According to Nostrum documentation, two fields use
**`DateTime.t()`** type, NOT integers:

1. `premium_since` - Currently typed as `:integer`, should be **`:datetime`** or
   handle DateTime structs
2. `communication_disabled_until` - Currently typed as `:integer`, should be
   **`:datetime`** or handle DateTime structs

Meanwhile, `joined_at` uses Unix timestamp integers.

**Recommendation**: Update these fields to use Ash's datetime types or ensure
proper conversion in the `new/1` function.

---

## Issues Found

### 1. Missing Fields from Discord API (Not in Nostrum Yet)

#### 1.1 ~~Missing: `user` field~~ - Actually Correct! ✅

**Status**: ✅ **Implementation is correct**

**Discord API**:

```typescript
user: APIUser; // Required, non-nullable
```

**Nostrum actual type**: `user_id: integer | nil`

**Current implementation**:

```elixir
field :user_id, :integer, description: "The user ID (can be nil for partial Member objects)"
```

**Analysis**:

- Discord API provides full `user` object
- **Nostrum transforms this to just `user_id` (integer)**
- Our implementation correctly matches Nostrum's structure
- Nostrum docs confirm `user_id` can be `nil` for partial member objects

**Conclusion**: No change needed. The current implementation correctly matches
Nostrum's transformed data structure.

#### 1.2 Missing: `banner` field

**Severity**: ⚠️ **LOW** - Not in Nostrum yet

**Discord API v10**:

```typescript
banner?: string | null  // Optional and nullable
```

**Nostrum**: Does NOT include this field yet

**Analysis**:

- Discord API v10 includes `banner` field
- Nostrum.Struct.Guild.Member does NOT include this field
- Adding it would be premature until Nostrum supports it

**Recommendation**: **Do NOT add** until Nostrum includes it. Monitor Nostrum
updates for when this field is added.

#### 1.3 Missing: `avatar_decoration_data` field

**Severity**: ⚠️ **LOW** - Not in Nostrum yet

**Discord API v10**:

```typescript
avatar_decoration_data?: APIAvatarDecorationData | null  // Optional and nullable
```

**Nostrum**: Does NOT include this field yet

**Analysis**:

- Discord API v10 includes `avatar_decoration_data` field
- Nostrum.Struct.Guild.Member does NOT include this field
- Adding it would be premature until Nostrum supports it

**Recommendation**: **Do NOT add** until Nostrum includes it. Monitor Nostrum
updates for when this field is added.

---

### 2. Field Type Issues

#### 2.1 ~~`roles` - Incorrect type~~ - Actually Correct! ✅

**Status**: ✅ **Implementation is correct**

**Discord API**:

```typescript
roles: Snowflake[]  // Array of strings (Snowflake IDs are strings)
```

**Nostrum actual type**: List of integers

**Current implementation**:

```elixir
field :roles, {:array, :integer}, allow_nil?: false, description: "A list of role ids"
```

**Analysis**:

- Discord API returns Snowflakes as strings
- **Nostrum converts Snowflakes to integers**
- Our implementation correctly matches Nostrum's transformed data
- `allow_nil?: false` is correct (roles is a required field)

**Minor improvement** (optional): Update description to note Nostrum's
conversion:

```elixir
field :roles, {:array, :integer}, allow_nil?: false,
  description: "A list of role ids (Nostrum converts Snowflakes to integers)"
```

#### 2.2 `joined_at` - Type correct, but documentation could be clearer

**Severity**: ⚠️ **LOW** - Minor documentation improvement

**Discord API**:

```typescript
joined_at: string | null; // Required field, but value can be null
```

**Nostrum actual type**: `integer | nil` (Unix timestamp)

**Current implementation**:

```elixir
field :joined_at, :integer, description: "Unix timestamp when the user joined the guild"
```

**Analysis**:

- Discord API returns ISO8601 timestamp strings
- **Nostrum converts to Unix timestamp integers**
- Nostrum allows `nil` values
- Type `:integer` is correct
- Default `allow_nil?: true` handles nil values correctly

**Minor improvement** (optional): Update description to note conversion and nil:

```elixir
field :joined_at, :integer,
  description: "Unix timestamp when the user joined the guild (Nostrum converts from ISO8601; can be nil)"
```

#### 2.3 `premium_since` - Incorrect type ⚠️ CRITICAL

**Severity**: ❌ **HIGH** - Type mismatch with Nostrum

**Discord API**:

```typescript
premium_since?: string | null  // Optional and nullable ISO8601 timestamp
```

**Nostrum actual type**: `DateTime.t() | nil`

**Current implementation**:

```elixir
field :premium_since, :integer,
  description: "Unix timestamp when the user started boosting the guild"
```

**Issues**:

1. Nostrum provides **`DateTime.t()`** struct, NOT integer
2. Current `:integer` type will cause type errors when Nostrum provides DateTime
3. Missing explicit handling of nil values

**Recommended change**:

```elixir
# Option 1: Use Ash's datetime type (if it handles Elixir DateTime)
field :premium_since, :datetime,
  description: "DateTime when the user started boosting the guild"

# Option 2: Convert in new/1 function and store as integer
# Keep :integer type but add conversion logic in new/1
```

#### 2.4 `communication_disabled_until` - Incorrect type ⚠️ CRITICAL

**Severity**: ❌ **HIGH** - Type mismatch with Nostrum

**Discord API**:

```typescript
communication_disabled_until?: string | null  // Optional and nullable ISO8601 timestamp
```

**Nostrum actual type**: `DateTime.t() | nil`

**Current implementation**:

```elixir
field :communication_disabled_until, :integer,
  description: "Unix timestamp when the user's timeout will expire (if they're timed out)"
```

**Issues**:

1. Nostrum provides **`DateTime.t()`** struct, NOT integer
2. Current `:integer` type will cause type errors when Nostrum provides DateTime
3. Missing explicit handling of nil values

**Recommended change**:

```elixir
# Option 1: Use Ash's datetime type (if it handles Elixir DateTime)
field :communication_disabled_until, :datetime,
  description: "DateTime when the user's timeout will expire; nil if not timed out"

# Option 2: Convert in new/1 function and store as integer
# Keep :integer type but add conversion logic in new/1
```

#### 2.5 `flags` - Missing allow_nil?

**Severity**: ⚠️ **LOW**

**Discord API**:

```typescript
flags: GuildMemberFlags; // Required, non-nullable integer bitfield
```

**Current implementation**:

```elixir
field :flags, :integer, description: "Guild member flags"
```

**Issue**: Missing `allow_nil?: false` to explicitly mark as required.

**Recommended change**:

```elixir
field :flags, :integer, allow_nil?: false, description: "Guild member flags represented as a bit set"
```

---

### 3. Incorrect `allow_nil?` Settings (7)

#### 3.1 `user_id` (or `user`) - Should be `allow_nil?: false`

**Severity**: ❌ **HIGH**

The `user` field in Discord API is **required and non-nullable**.

**Current**:

```elixir
field :user_id, :integer, description: "The user ID (can be nil for partial Member objects)"
```

**Should be**:

```elixir
field :user_id, :integer, allow_nil?: false,
  description: "The user ID from the user object"
```

**Reason**: The Discord API marks `user: APIUser` as required (no `?`) and
non-nullable (no `| null`).

#### 3.2 `nick` - Missing allow_nil? (defaults to false, should be true)

**Severity**: ❌ **MEDIUM**

**Discord API**:

```typescript
nick?: string | null  // Optional and nullable
```

**Current**:

```elixir
field :nick, :string, description: "The nickname of the member"
```

**Should be**:

```elixir
field :nick, :string, description: "The nickname of the member"
```

**Note**: Actually, since `allow_nil?` defaults to `true` in Ash.TypedStruct,
this is likely correct. However, it's better to be explicit when the field is
both optional and nullable.

#### 3.3 `joined_at` - Should have `allow_nil?: true` (nullable value)

**Severity**: ❌ **MEDIUM**

**Discord API**:

```typescript
joined_at: string | null; // Required field, but value can be null
```

**Current**:

```elixir
field :joined_at, :integer, description: "Unix timestamp when the user joined the guild"
```

**Should be**:

```elixir
field :joined_at, :integer,
  description: "Unix timestamp when the user joined the guild (can be null)"
```

**Note**: The field itself is not optional (no `?` after field name), but the
value can be null (`| null`), so we might need `allow_nil?: true` depending on
Nostrum's behavior.

#### 3.4 `deaf` - Missing `allow_nil?: false`

**Severity**: ⚠️ **LOW**

**Discord API**:

```typescript
deaf: boolean; // Required, non-nullable
```

**Current**:

```elixir
field :deaf, :boolean, description: "Whether the user is deafened in voice channels"
```

**Should be**:

```elixir
field :deaf, :boolean, allow_nil?: false,
  description: "Whether the user is deafened in voice channels"
```

**Note**: In some contexts (like interaction resolved data), this field may be
missing. If Nostrum handles this by providing nil, we may need
`allow_nil?: true`.

#### 3.5 `mute` - Missing `allow_nil?: false`

**Severity**: ⚠️ **LOW**

**Discord API**:

```typescript
mute: boolean; // Required, non-nullable
```

**Current**:

```elixir
field :mute, :boolean, description: "Whether the user is muted in voice channels"
```

**Should be**:

```elixir
field :mute, :boolean, allow_nil?: false,
  description: "Whether the user is muted in voice channels"
```

**Note**: In some contexts (like interaction resolved data), this field may be
missing. If Nostrum handles this by providing nil, we may need
`allow_nil?: true`.

#### 3.6 `pending` - Missing `allow_nil?: true` for optional field

**Severity**: ⚠️ **LOW**

**Discord API**:

```typescript
pending?: boolean  // Optional, but not nullable
```

**Current**:

```elixir
field :pending, :boolean,
  description: "Whether the user has not yet passed the guild's Membership Screening requirements"
```

**Analysis**:

- Field is **optional** (marked with `?` after field name)
- But value is **not nullable** (no `| null` in type)
- In Elixir/Ash context, "optional" typically means the field can be absent
  (nil)

**Should be**:

```elixir
field :pending, :boolean,
  description: "Whether the user has not yet passed the guild's Membership Screening requirements"
```

**Note**: Since it's optional but not nullable, if present it must be a boolean.
The default `allow_nil?: true` in Ash.TypedStruct should handle the optional
nature correctly.

#### 3.7 `avatar` - Current setting is likely correct

**Severity**: ✅ **OK**

**Discord API**:

```typescript
avatar?: string | null  // Optional and nullable
```

**Current**:

```elixir
field :avatar, :string, description: "The member's guild-specific avatar hash"
```

**Analysis**: Default `allow_nil?: true` is correct for optional and nullable
fields.

---

## Recommended Changes Summary

### Priority 1 (CRITICAL - Must Fix)

**1. Fix `premium_since` type to handle DateTime.t()**:

```elixir
# Option A: Use Ash's datetime type (recommended)
field :premium_since, :datetime,
  description: "DateTime when the user started boosting the guild"

# Option B: Add conversion in new/1 function
# Convert DateTime.t() to Unix timestamp integer in the new/1 function
```

**2. Fix `communication_disabled_until` type to handle DateTime.t()**:

```elixir
# Option A: Use Ash's datetime type (recommended)
field :communication_disabled_until, :datetime,
  description: "DateTime when the user's timeout will expire; nil if not timed out"

# Option B: Add conversion in new/1 function
# Convert DateTime.t() to Unix timestamp integer in the new/1 function
```

### Priority 2 (Optional Documentation Improvements)

**3. Update field descriptions for clarity** (optional but recommended):

```elixir
# roles - note Nostrum's Snowflake conversion
field :roles, {:array, :integer}, allow_nil?: false,
  description: "A list of role ids (Nostrum converts Snowflakes to integers)"

# joined_at - note conversion and nil possibility
field :joined_at, :integer,
  description: "Unix timestamp when the user joined the guild (Nostrum converts from ISO8601; can be nil)"
```

### Future Considerations (When Nostrum Adds Support)

**Monitor Nostrum updates for these Discord API v10 fields**:

- `banner` - Guild member banner hash
- `avatar_decoration_data` - Avatar decoration data

These fields exist in Discord API v10 but are not yet in
Nostrum.Struct.Guild.Member. Do NOT add them until Nostrum supports them.

---

## Complete Corrected Implementation

Here's what the corrected TypedStruct should look like, based on verified
Nostrum data types:

```elixir
typed_struct do
  # User identification (Nostrum provides user_id, not full user object)
  field :user_id, :integer,
    description: "The user ID (can be nil for partial Member objects)"

  # Customization fields
  field :nick, :string,
    description: "The nickname of the member"

  field :avatar, :string,
    description: "The member's guild-specific avatar hash"

  # Role and permissions
  field :roles, {:array, :integer}, allow_nil?: false,
    description: "A list of role ids (Nostrum converts Snowflakes to integers)"

  # Timestamps
  field :joined_at, :integer,
    description: "Unix timestamp when the user joined the guild (Nostrum converts from ISO8601; can be nil)"

  # CRITICAL FIX: These are DateTime.t() in Nostrum, not integers!
  field :premium_since, :datetime,
    description: "DateTime when the user started boosting the guild"

  # Voice state (Nostrum allows nil despite Discord API marking as required)
  field :deaf, :boolean,
    description: "Whether the user is deafened in voice channels"

  field :mute, :boolean,
    description: "Whether the user is muted in voice channels"

  # Moderation and status
  # CRITICAL FIX: This is DateTime.t() in Nostrum, not integer!
  field :communication_disabled_until, :datetime,
    description: "DateTime when the user's timeout will expire; nil if not timed out"

  field :pending, :boolean,
    description: "Whether the user has not yet passed the guild's Membership Screening requirements"

  # Flags (Nostrum allows nil)
  field :flags, :integer,
    description: "Guild member flags represented as a bit set"
end
```

**Key changes from current implementation**:

1. `premium_since`: Changed from `:integer` to `:datetime` (Nostrum uses
   DateTime.t())
2. `communication_disabled_until`: Changed from `:integer` to `:datetime`
   (Nostrum uses DateTime.t())
3. Removed explicit `allow_nil?: false` from fields where Nostrum allows nil
   (deaf, mute, flags)
4. Updated descriptions to note Nostrum's transformations

---

## Notes and Considerations

### 1. Nostrum Data Transformations - VERIFIED ✅

**CONFIRMED** via Nostrum.Struct.Guild.Member documentation:

- ✅ **Timestamps**: Nostrum uses **Unix timestamp integers** (`joined_at`) OR
  **`DateTime.t()`** structs (`premium_since`, `communication_disabled_until`)
- ✅ **Snowflakes**: Nostrum converts Snowflake strings to **integers**
  (user_id, role ids)
- ✅ **User object**: Nostrum uses **`user_id`** (integer) instead of full user
  object
- ✅ **Optional/nullable fields**: Nostrum allows `nil` for all optional fields

**Critical findings**:

1. `communication_disabled_until` and `premium_since` are **`DateTime.t()`**,
   NOT integers!
2. All fields in Nostrum can be `nil`, matching Discord's optional/nullable
   semantics
3. `user_id` can be `nil` for partial member objects (confirmed in Nostrum docs)
4. Nostrum uses integers for timestamps (except DateTime fields) and Snowflakes

### 2. Partial Member Objects

The current implementation mentions "partial Member objects" where `user_id` can
be nil. However, according to the Discord API, the `user` field is always
required. Partial member objects might be a Nostrum-specific concept or might
refer to specific Discord contexts (like interaction resolved data).

### 3. Field Presence in Different Contexts

According to Discord API issues found during research:

- Fields like `deaf` and `mute` may not be present in interaction resolved data
- This suggests we might need to allow nil for these fields despite them being
  required in the base API

Consider whether AshDiscord needs to handle multiple contexts (gateway events vs
interaction data vs API responses) differently.

### 4. Type Consistency

Ensure consistency with other payload modules in the codebase:

- Are timestamps consistently integers or strings?
- Are Snowflakes consistently integers or strings?
- How are nested objects handled (as maps, as nested TypedStructs, etc.)?

---

## Next Steps

1. **Consult Nostrum documentation** to verify type transformations
2. **Review Nostrum.Struct.Guild.Member** source code
3. **Check other payload modules** for consistency patterns
4. **Test with actual Discord data** to see what Nostrum provides
5. **Update the Member payload** based on findings
6. **Update tests** to cover new/changed fields
7. **Update documentation** to reflect Discord API v10 compliance

---

## References

- [Discord API v10 - Guild Member Object](https://discord.com/developers/docs/resources/guild#guild-member-object)
- [discord-api-types v10 - APIGuildMember](https://discord-api-types.dev/api/discord-api-types-v10/interface/APIGuildMember)
- [discord-api-types GitHub - guild.ts](https://github.com/discordjs/discord-api-types/blob/main/payloads/v10/guild.ts)
- [Nostrum - Guild.Member](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Member.html)
