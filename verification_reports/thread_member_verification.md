# ThreadMember Payload Verification Report

**Date:** 2025-10-05 **File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/thread_member.ex`
**Discord API Reference:**
https://discord.com/developers/docs/resources/channel#thread-member-object
**Nostrum Reference:**
https://hexdocs.pm/nostrum/Nostrum.Struct.ThreadMember.html

---

## Summary

The ThreadMember payload has **3 fields with incorrect `allow_nil?` settings**
and **1 missing field** from the Discord API specification.

---

## Field-by-Field Analysis

### ✅ Correct Fields

#### 1. `flags`

- **Current Definition:** `field :flags, :integer, allow_nil?: false`
- **Discord API:** `flags` (required, non-nullable) - ThreadMemberFlags bitfield
- **Nostrum:** `flags :: non_neg_integer()`
- **Status:** ✅ **CORRECT** - Required field, properly marked as non-nullable

---

### ⚠️ Fields Requiring Corrections

#### 2. `id`

- **Current Definition:** `field :id, :integer`
- **Discord API:** `id?` (optional) - The id of the thread, omitted within
  GUILD_CREATE events
- **Nostrum:** `id :: Nostrum.Snowflake.t() | nil`
- **Issue:** Missing `allow_nil?: true` - field is optional and can be
  omitted/nil
- **Correction Needed:** YES

**Recommended Fix:**

```elixir
field :id, :integer,
  allow_nil?: true,
  description: "The id of the thread (omitted within GUILD_CREATE events)"
```

---

#### 3. `user_id`

- **Current Definition:** `field :user_id, :integer`
- **Discord API:** `user_id?` (optional) - The id of the user, omitted within
  GUILD_CREATE events
- **Nostrum:** `user_id :: Nostrum.Struct.User.id() | nil`
- **Issue:** Missing `allow_nil?: true` - field is optional and can be
  omitted/nil
- **Correction Needed:** YES

**Recommended Fix:**

```elixir
field :user_id, :integer,
  allow_nil?: true,
  description: "The id of the user (omitted within GUILD_CREATE events)"
```

---

#### 4. `join_timestamp`

- **Current Definition:**
  `field :join_timestamp, :utc_datetime, allow_nil?: false`
- **Discord API:** `join_timestamp` (required) - ISO8601 timestamp of when the
  user last joined
- **Nostrum:** `join_timestamp :: DateTime.t()`
- **Issue:** Field is correctly marked as required, but Nostrum's type is
  `DateTime.t()` which is non-nullable by default
- **Note:** The `allow_nil?: false` is technically correct but redundant since
  the field is required
- **Status:** ✅ **FUNCTIONALLY CORRECT** (explicit `allow_nil?: false` is fine
  but not necessary)

---

#### 5. `guild_id`

- **Current Definition:** `field :guild_id, :integer`
- **Discord API:** NOT present in the Thread Member Object structure
- **Nostrum:** `guild_id :: Nostrum.Struct.Guild.id() | nil` (Nostrum extension)
- **Issue:** Missing `allow_nil?: true` - field can be nil per Nostrum
- **Note:** This is a Nostrum-specific field not in the official Discord API
- **Correction Needed:** YES

**Recommended Fix:**

```elixir
field :guild_id, :integer,
  allow_nil?: true,
  description: "ID of the guild containing the thread (Nostrum extension)"
```

---

### 🔍 Missing Fields

#### 6. `member`

- **Discord API:** `member?` (optional) - APIGuildMember object
- **Description:** Additional information about the user (only present when
  `with_member` is set to true when calling List Thread Members or Get Thread
  Member, omitted in GUILD_CREATE event)
- **Nostrum:** NOT present in Nostrum.Struct.ThreadMember
- **Status:** ⚠️ **MISSING** - Discord API field not present in Nostrum

**Note:** This field is only present in specific API contexts (when
`with_member=true` is used). Since Nostrum does not include this field in its
ThreadMember struct, it's reasonable to omit it from the AshDiscord payload to
maintain compatibility with Nostrum. However, this should be documented.

**Recommendation:** Document that the `member` field is intentionally omitted
for Nostrum compatibility.

---

## Summary of Required Changes

### Fields to Update (3)

1. **`id`** - Add `allow_nil?: true`
2. **`user_id`** - Add `allow_nil?: true`
3. **`guild_id`** - Add `allow_nil?: true`

### Optional Cleanup (1)

4. **`join_timestamp`** - The explicit `allow_nil?: false` can be removed as
   it's the default, but keeping it is acceptable for clarity

---

## Recommended Complete Implementation

```elixir
defmodule AshDiscord.Consumer.Payloads.ThreadMember do
  @moduledoc """
  TypedStruct wrapper for Discord ThreadMember data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.ThreadMember.t()`.

  ## Note on Missing Fields

  The `member` field from the Discord API Thread Member Object is not included
  because it is not present in Nostrum's ThreadMember struct. This field is
  only populated when using specific API endpoints with the `with_member=true`
  parameter.

  ## References
  - [Discord API - Thread Member](https://discord.com/developers/docs/resources/channel#thread-member-object)
  - [Nostrum - ThreadMember](https://hexdocs.pm/nostrum/Nostrum.Struct.ThreadMember.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: true,
      description: "The id of the thread (omitted within GUILD_CREATE events)"

    field :user_id, :integer,
      allow_nil?: true,
      description: "The id of the user (omitted within GUILD_CREATE events)"

    field :join_timestamp, :utc_datetime,
      description: "The timestamp of when the user last joined the thread"

    field :flags, :integer,
      description: "User thread settings flags"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "ID of the guild containing the thread (Nostrum extension)"
  end

  @doc """
  Create a ThreadMember TypedStruct from a Nostrum ThreadMember struct.

  Accepts a `Nostrum.Struct.ThreadMember.t()` and creates an AshDiscord ThreadMember TypedStruct.
  """
  def new(%Nostrum.Struct.ThreadMember{} = nostrum_thread_member) do
    super(Map.from_struct(nostrum_thread_member))
  end
end
```

---

## Verification Details

### Discord API Thread Member Object Structure

From the official Discord API documentation and discord-api-types:

```typescript
interface APIThreadMember {
  flags: ThreadMemberFlags; // Required
  id?: string; // Optional
  join_timestamp: string; // Required (ISO8601)
  member?: APIGuildMember; // Optional
  user_id?: string; // Optional
}
```

### Nostrum ThreadMember Structure

From Nostrum documentation:

```elixir
%Nostrum.Struct.ThreadMember{
  flags: non_neg_integer(),           # Required
  guild_id: Nostrum.Struct.Guild.id() | nil,  # Optional (Nostrum extension)
  id: Nostrum.Snowflake.t() | nil,    # Optional
  join_timestamp: DateTime.t(),       # Required
  user_id: Nostrum.Struct.User.id() | nil     # Optional
}
```

---

## Field Nullability Rules Applied

Based on Discord API conventions:

- **Field marked with `?` after name** (e.g., `id?`) → Optional field →
  `allow_nil?: true`
- **Field with no `?`** (e.g., `flags`) → Required field → `allow_nil?: false`
  (or omit, as it's default)
- **Nostrum type with `| nil`** → Field can be nil → `allow_nil?: true`

---

## Conclusion

The ThreadMember payload requires **3 corrections** to properly align with both
Discord API and Nostrum specifications:

1. Add `allow_nil?: true` to `id`
2. Add `allow_nil?: true` to `user_id`
3. Add `allow_nil?: true` to `guild_id`

The `member` field from Discord API is intentionally omitted for Nostrum
compatibility and should be documented in the module's @moduledoc.
