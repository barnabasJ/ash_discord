# Emoji Payload Verification Report

**File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/emoji.ex`

**Discord API Reference:**
https://discord-api-types.dev/api/discord-api-types-v10/interface/APIEmoji

**Date:** 2025-10-05

---

## Summary

Verification of the Emoji payload type against Discord API v10 specification
revealed **5 fields requiring corrections**. All fields present in Discord API
are implemented, with no missing or extra fields.

## Field-by-Field Analysis

### ✅ Correct Fields

| Field            | Current Type                  | Discord API Type            | Status                          |
| ---------------- | ----------------------------- | --------------------------- | ------------------------------- |
| `name`           | `string`, `allow_nil?: false` | `null \| string` (required) | ✅ Needs correction - see below |
| `animated`       | `boolean`                     | `boolean` (optional)        | ✅ Needs correction - see below |
| `available`      | `boolean`                     | `boolean` (optional)        | ✅ Needs correction - see below |
| `managed`        | `boolean`                     | `boolean` (optional)        | ✅ Needs correction - see below |
| `require_colons` | `boolean`                     | `boolean` (optional)        | ✅ Needs correction - see below |

### ❌ Fields Requiring Corrections

#### 1. **Field: `id`**

**Current Implementation:**

```elixir
field :id, :integer, description: "Id of the emoji"
```

**Discord API Specification:**

- Type: `null | string` (required field, but nullable)
- Description: "Emoji id"

**Issues:**

- ❌ Wrong type: Should be `string` (Discord snowflake IDs are strings), not
  `:integer`
- ❌ Missing `allow_nil?: true`: Field is nullable in Discord API

**Recommended Fix:**

```elixir
field :id, :string,
  allow_nil?: true,
  description: "Emoji id (snowflake, can be null for standard Unicode emoji)"
```

---

#### 2. **Field: `name`**

**Current Implementation:**

```elixir
field :name, :string, allow_nil?: false, description: "Name of the emoji"
```

**Discord API Specification:**

- Type: `null | string` (required field, but nullable)
- Description: "Emoji name (can be null only in reaction emoji objects)"

**Issues:**

- ❌ Wrong `allow_nil?`: Should be `true` (API specifies it can be null in
  reaction emoji objects)

**Recommended Fix:**

```elixir
field :name, :string,
  allow_nil?: true,
  description: "Name of the emoji (can be null only in reaction emoji objects)"
```

---

#### 3. **Field: `roles`**

**Current Implementation:**

```elixir
field :roles, {:array, :integer}, description: "Roles this emoji is whitelisted to"
```

**Discord API Specification:**

- Type: `string[]` (optional)
- Description: "Roles this emoji is whitelisted to"

**Issues:**

- ❌ Wrong element type: Should be `string` (role IDs are snowflakes/strings),
  not `:integer`
- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :roles, {:array, :string},
  allow_nil?: true,
  description: "Roles this emoji is whitelisted to (array of role ID snowflakes)"
```

---

#### 4. **Field: `user`**

**Current Implementation:**

```elixir
field :user, :map, description: "User that created this emoji"
```

**Discord API Specification:**

- Type: `APIUser` (optional)
- Description: "User that created this emoji"

**Issues:**

- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :user, :map,
  allow_nil?: true,
  description: "User that created this emoji"
```

---

#### 5. **Field: `require_colons`**

**Current Implementation:**

```elixir
field :require_colons, :boolean, description: "Whether this emoji must be wrapped in colons"
```

**Discord API Specification:**

- Type: `boolean` (optional)
- Description: "Whether this emoji must be wrapped in colons"

**Issues:**

- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :require_colons, :boolean,
  allow_nil?: true,
  description: "Whether this emoji must be wrapped in colons"
```

---

#### 6. **Field: `managed`**

**Current Implementation:**

```elixir
field :managed, :boolean, description: "Whether this emoji is managed"
```

**Discord API Specification:**

- Type: `boolean` (optional)
- Description: "Whether this emoji is managed"

**Issues:**

- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :managed, :boolean,
  allow_nil?: true,
  description: "Whether this emoji is managed"
```

---

#### 7. **Field: `animated`**

**Current Implementation:**

```elixir
field :animated, :boolean, description: "Whether this emoji is animated"
```

**Discord API Specification:**

- Type: `boolean` (optional)
- Description: "Whether this emoji is animated"

**Issues:**

- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :animated, :boolean,
  allow_nil?: true,
  description: "Whether this emoji is animated"
```

---

#### 8. **Field: `available`**

**Current Implementation:**

```elixir
field :available, :boolean,
  description: "Whether this emoji can be used, may be false due to loss of Server Boosts"
```

**Discord API Specification:**

- Type: `boolean` (optional)
- Description: "Whether this emoji can be used, may be false due to loss of
  Server Boosts"

**Issues:**

- ❌ Missing `allow_nil?: true`: Field is optional in Discord API

**Recommended Fix:**

```elixir
field :available, :boolean,
  allow_nil?: true,
  description: "Whether this emoji can be used, may be false due to loss of Server Boosts"
```

---

## Missing Fields from Discord API

**None** - All Discord API fields are present in the implementation.

## Extra Fields Not in Discord API

**None** - No extra fields found.

## Complete Corrected TypedStruct

Here's the complete corrected `typed_struct` block:

```elixir
typed_struct do
  field :id, :string,
    allow_nil?: true,
    description: "Emoji id (snowflake, can be null for standard Unicode emoji)"

  field :name, :string,
    allow_nil?: true,
    description: "Name of the emoji (can be null only in reaction emoji objects)"

  field :roles, {:array, :string},
    allow_nil?: true,
    description: "Roles this emoji is whitelisted to (array of role ID snowflakes)"

  field :user, :map,
    allow_nil?: true,
    description: "User that created this emoji"

  field :require_colons, :boolean,
    allow_nil?: true,
    description: "Whether this emoji must be wrapped in colons"

  field :managed, :boolean,
    allow_nil?: true,
    description: "Whether this emoji is managed"

  field :animated, :boolean,
    allow_nil?: true,
    description: "Whether this emoji is animated"

  field :available, :boolean,
    allow_nil?: true,
    description: "Whether this emoji can be used, may be false due to loss of Server Boosts"
end
```

## Key Insights

### 1. **Snowflake ID Types**

Discord uses string-based snowflake IDs, not integers. The `id` and `roles`
fields must use `:string` type.

### 2. **Optional Fields Pattern**

In Discord API, "optional" means the field may not be present in the response.
In Elixir TypedStruct, this should be represented with `allow_nil?: true`.

### 3. **Nullable vs Optional**

Discord API distinguishes between:

- **Optional fields** (may not be present): `field?` → `allow_nil?: true`
- **Nullable fields** (present but value can be null): `?type` →
  `allow_nil?: true`
- **Both** (optional AND nullable): `field? ?type` → `allow_nil?: true`

In this API, most fields are simply optional (not explicitly nullable), except
`id` and `name` which are both required but nullable.

### 4. **Consistency with Nostrum**

Verify that Nostrum's `Nostrum.Struct.Emoji.t()` matches these types. If Nostrum
uses integers for IDs, the conversion in the `new/1` function may need
adjustment.

## Recommended Actions

1. **Update all 8 fields** with the corrections specified above
2. **Test the conversion** from Nostrum structs to ensure ID type conversion
   works correctly
3. **Update tests** to validate nullable fields properly handle `nil` values
4. **Consider creating a User TypedStruct** for the `user` field instead of
   using `:map`
5. **Verify Nostrum compatibility** - check if Nostrum uses strings or integers
   for snowflake IDs

## References

- [Discord API - Emoji (discord-api-types v10)](https://discord-api-types.dev/api/discord-api-types-v10/interface/APIEmoji)
- [Discord API - Emoji Resource](https://discord.com/developers/docs/resources/emoji)
- [Nostrum - Emoji](https://hexdocs.pm/nostrum/Nostrum.Struct.Emoji.html)
