# Role Payload Verification Report

**Date:** 2025-10-05 **File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/role.ex`
**Discord API Reference:**
https://discord.com/developers/docs/topics/permissions#role-object **Discord API
Types Reference:**
https://discord-api-types.dev/api/discord-api-types-v10/interface/APIRole
**Nostrum Reference:** https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Role.html

## Summary

The current Role payload implementation is **incomplete** and has several
issues:

- **Missing Fields:** 3 critical Discord API fields
- **Type Mismatches:** 2 fields have incorrect types
- **Nullability Issues:** 2 fields have incorrect `allow_nil?` settings
- **Total Issues:** 7 corrections needed

---

## Discord API Role Object Structure

Based on Discord API v10 (latest), the Role object has these fields:

| Field         | Type                | Optional? | Nullable? | Description                                          |
| ------------- | ------------------- | --------- | --------- | ---------------------------------------------------- |
| id            | string (snowflake)  | No        | No        | Role id                                              |
| name          | string              | No        | No        | Role name                                            |
| color         | number (integer)    | No        | No        | Integer representation of hexadecimal color code     |
| colors        | APIRoleColors       | Yes       | No        | The role's colors (new field, color still supported) |
| hoist         | boolean             | No        | No        | If this role is pinned in the user listing           |
| position      | number (integer)    | No        | No        | Position of this role                                |
| permissions   | string              | No        | No        | Permission bit set                                   |
| managed       | boolean             | No        | No        | Whether this role is managed by an integration       |
| mentionable   | boolean             | No        | No        | Whether this role is mentionable                     |
| icon          | string (hash)       | Yes       | Yes       | The role icon hash                                   |
| unicode_emoji | string              | Yes       | Yes       | The role unicode emoji as a standard emoji           |
| flags         | RoleFlags (integer) | No        | No        | Role flags (bitfield)                                |
| tags          | APIRoleTags         | Yes       | No        | The tags this role has                               |

### APIRoleTags Structure

| Field                   | Type               | Optional? | Description                                         |
| ----------------------- | ------------------ | --------- | --------------------------------------------------- |
| bot_id                  | string (snowflake) | Yes       | The id of the bot this role belongs to              |
| integration_id          | string (snowflake) | Yes       | The id of the integration this role belongs to      |
| premium_subscriber      | null               | Yes       | Whether this is the guild's premium subscriber role |
| subscription_listing_id | string (snowflake) | Yes       | The id of this role's subscription sku and listing  |
| available_for_purchase  | null               | Yes       | Whether this role is available for purchase         |
| guild_connections       | null               | Yes       | Whether this role is a guild's linked role          |

### RoleFlags Enum

- `InPrompt = 1` - Role can be selected by members in an onboarding prompt

---

## Field-by-Field Analysis

### ✅ Correct Fields

These fields are correctly defined:

1. **name** - ✅ Correct type (string), correct nullability (required,
   non-nullable)
2. **color** - ✅ Correct type (integer), correct nullability (required,
   non-nullable)
3. **hoist** - ✅ Correct type (boolean), correct nullability (required,
   non-nullable)
4. **position** - ✅ Correct type (integer), correct nullability (required,
   non-nullable)
5. **managed** - ✅ Correct type (boolean), correct nullability (required,
   non-nullable)
6. **mentionable** - ✅ Correct type (boolean), correct nullability (required,
   non-nullable)

### ⚠️ Fields Needing Corrections

#### 1. **id** - Type Mismatch

**Current:**

```elixir
field :id, :integer, allow_nil?: false, description: "The id of the role"
```

**Issue:** Discord uses string snowflakes for IDs in the API (though Nostrum
converts them to integers).

**Discord API:** `id: string` (snowflake) **Nostrum:** `id: Nostrum.Snowflake.t`
(integer)

**Analysis:** The current implementation follows Nostrum's type, which is
acceptable since we're wrapping Nostrum structs. However, it's worth noting that
the Discord API sends this as a string snowflake.

**Recommendation:** Keep as `:integer` to match Nostrum, but add a note in the
description.

```elixir
field :id, :integer,
  allow_nil?: false,
  description: "The id of the role (snowflake, represented as integer by Nostrum)"
```

#### 2. **permissions** - Type Mismatch

**Current:**

```elixir
field :permissions, :integer, allow_nil?: false, description: "The permission bit set"
```

**Issue:** Discord API v10+ sends permissions as a **string**, not an integer,
to support 53-bit precision.

**Discord API:** `permissions: string` (permission bit set) **Nostrum:**
`permissions: integer`

**Analysis:** Nostrum still uses integers for permissions, but Discord API has
changed to strings. This is a known compatibility issue between Nostrum's older
approach and Discord's current API.

**Recommendation:** Keep as `:integer` to match Nostrum, but add a note about
the Discord API difference.

```elixir
field :permissions, :integer,
  allow_nil?: false,
  description: "The permission bit set (sent as string by Discord API, converted to integer by Nostrum)"
```

#### 3. **icon** - Incorrect Nullability

**Current:**

```elixir
field :icon, :string, description: "The hash of the role icon"
```

**Issue:** Missing `allow_nil?` setting. In Discord API, this field is optional
and nullable (`icon?: null | string`).

**Discord API:** `icon?: null | string` (optional, nullable) **Nostrum:**
`icon: string | nil`

**Recommendation:** Add `allow_nil?: true`.

```elixir
field :icon, :string,
  allow_nil?: true,
  description: "The hash of the role icon (optional, nullable)"
```

#### 4. **unicode_emoji** - Incorrect Nullability

**Current:**

```elixir
field :unicode_emoji, :string,
  description: "The standard unicode character emoji icon for the role"
```

**Issue:** Missing `allow_nil?` setting. In Discord API, this field is optional
and nullable (`unicode_emoji?: null | string`).

**Discord API:** `unicode_emoji?: null | string` (optional, nullable)
**Nostrum:** `unicode_emoji: string | nil`

**Recommendation:** Add `allow_nil?: true`.

```elixir
field :unicode_emoji, :string,
  allow_nil?: true,
  description: "The standard unicode character emoji icon for the role (optional, nullable)"
```

### ❌ Missing Fields

These fields are in the Discord API but not in our payload:

#### 1. **flags** - MISSING (Required)

**Discord API:** `flags: RoleFlags` (integer bitfield, required, non-nullable)
**Nostrum:** Not documented in Nostrum.Struct.Guild.Role

**Issue:** This is a required field in Discord API v10+. It's a bitfield where
`1 << 0` (value 1) represents `InPrompt` - whether the role can be selected in
onboarding prompts.

**Recommendation:** Add this field.

```elixir
field :flags, :integer,
  allow_nil?: false,
  default: 0,
  description: "Role flags (bitfield). 1 = InPrompt (role can be selected by members in an onboarding prompt)"
```

**Note:** Since Nostrum doesn't expose this field, we may need to check if it's
available in the raw payload. If not available from Nostrum, we might need to
add a note that this field is only available when using direct API payloads.

#### 2. **tags** - MISSING (Optional)

**Discord API:** `tags?: APIRoleTags` (optional object with nested fields)
**Nostrum:** Not documented in Nostrum.Struct.Guild.Role

**Issue:** This is an optional field containing metadata about special role
types (bot roles, integration roles, premium subscriber roles, etc.).

**Structure:**

- `bot_id?: string` - The id of the bot this role belongs to
- `integration_id?: string` - The id of the integration this role belongs to
- `premium_subscriber?: null` - Whether this is the guild's premium subscriber
  role
- `subscription_listing_id?: string` - The id of this role's subscription sku
  and listing
- `available_for_purchase?: null` - Whether this role is available for purchase
- `guild_connections?: null` - Whether this role is a guild's linked role

**Recommendation:** Add this field as a map.

```elixir
field :tags, :map,
  allow_nil?: true,
  description: """
  The tags this role has (optional). Possible fields:
  - bot_id (integer): The id of the bot this role belongs to
  - integration_id (integer): The id of the integration this role belongs to
  - premium_subscriber (null): Whether this is the guild's premium subscriber role
  - subscription_listing_id (integer): The id of this role's subscription sku and listing
  - available_for_purchase (null): Whether this role is available for purchase
  - guild_connections (null): Whether this role is a guild's linked role
  """
```

**Note:** Since Nostrum doesn't expose this field, we may need to check if it's
available in the raw payload.

#### 3. **colors** - MISSING (Optional, New Field)

**Discord API:** `colors?: APIRoleColors` (optional, new field added recently)
**Nostrum:** Not documented in Nostrum.Struct.Guild.Role

**Issue:** This is a newer field that provides more granular color information.
The `color` field is still supported for backwards compatibility.

**Recommendation:** Consider adding this field for completeness, but it's lower
priority since `color` is still the primary field.

```elixir
field :colors, :map,
  allow_nil?: true,
  description: "The role's colors (new field, color field still recommended for backwards compatibility)"
```

**Note:** This is a very recent addition and may not be widely used yet. Can be
added in a future update.

---

## Recommended Changes

### Complete Updated TypedStruct

Here's the recommended complete implementation:

```elixir
defmodule AshDiscord.Consumer.Payloads.Role do
  @moduledoc """
  TypedStruct wrapper for Discord Role data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.Role.t()`.

  ## References
  - [Discord API - Role](https://discord.com/developers/docs/topics/permissions#role-object)
  - [Nostrum - Guild.Role](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Role.html)
  """

  use Ash.TypedStruct

  typed_struct do
    # Required fields
    field :id, :integer,
      allow_nil?: false,
      description: "The id of the role (snowflake, represented as integer by Nostrum)"

    field :name, :string,
      allow_nil?: false,
      description: "The name of the role"

    field :color, :integer,
      allow_nil?: false,
      description: "The hexadecimal color code (integer representation)"

    field :hoist, :boolean,
      allow_nil?: false,
      description: "Whether the role is pinned in the user listing"

    field :position, :integer,
      allow_nil?: false,
      description: "The position of the role"

    field :permissions, :integer,
      allow_nil?: false,
      description: "The permission bit set (sent as string by Discord API, converted to integer by Nostrum)"

    field :managed, :boolean,
      allow_nil?: false,
      description: "Whether the role is managed by an integration"

    field :mentionable, :boolean,
      allow_nil?: false,
      description: "Whether the role is mentionable"

    field :flags, :integer,
      allow_nil?: false,
      default: 0,
      description: "Role flags (bitfield). 1 = InPrompt (role can be selected by members in an onboarding prompt)"

    # Optional/nullable fields
    field :icon, :string,
      allow_nil?: true,
      description: "The hash of the role icon (optional, nullable)"

    field :unicode_emoji, :string,
      allow_nil?: true,
      description: "The standard unicode character emoji icon for the role (optional, nullable)"

    field :tags, :map,
      allow_nil?: true,
      description: """
      The tags this role has (optional). Possible fields:
      - bot_id (integer): The id of the bot this role belongs to
      - integration_id (integer): The id of the integration this role belongs to
      - premium_subscriber (null): Whether this is the guild's premium subscriber role
      - subscription_listing_id (integer): The id of this role's subscription sku and listing
      - available_for_purchase (null): Whether this role is available for purchase
      - guild_connections (null): Whether this role is a guild's linked role
      """
  end

  @doc """
  Create a Role TypedStruct from a Nostrum Guild.Role struct.

  Accepts a `Nostrum.Struct.Guild.Role.t()` and creates an AshDiscord Role TypedStruct.
  Also handles being passed a Role payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = role_payload) do
    {:ok, role_payload}
  end

  def new(%Nostrum.Struct.Guild.Role{} = nostrum_role) do
    super(Map.from_struct(nostrum_role))
  end
end
```

---

## Notes on Nostrum Compatibility

**Important:** Nostrum v0.7.0 does not expose the following Discord API fields:

- `flags` (added in Discord API v10)
- `tags` (added in Discord API v9)
- `colors` (recently added to Discord API)

### Handling Nostrum Limitations

If these fields are not present in Nostrum structs, we have two options:

1. **Add with defaults:** Include the fields with `default: 0` (for flags) or
   `allow_nil?: true` (for tags/colors), acknowledging they won't be populated
   from Nostrum structs but will be available if we ever receive raw Discord API
   payloads.

2. **Wait for Nostrum update:** Don't add these fields until Nostrum supports
   them.

**Recommendation:** Add the fields with appropriate defaults/nullability. This
ensures our payload type is complete according to Discord API specification,
even if Nostrum doesn't populate them yet. The `new/1` function will simply not
set these fields when converting from Nostrum structs, and they'll use their
defaults or be nil.

---

## Priority of Changes

### High Priority (Correctness Issues)

1. ✅ **icon** - Add `allow_nil?: true` (currently missing nullability setting)
2. ✅ **unicode_emoji** - Add `allow_nil?: true` (currently missing nullability
   setting)

### Medium Priority (Completeness)

3. ✅ **flags** - Add required field with default value
4. ✅ **tags** - Add optional field for role metadata

### Low Priority (Documentation/Future)

5. ✅ **id** - Update description to note snowflake representation
6. ✅ **permissions** - Update description to note API string vs Nostrum integer
7. ⏸️ **colors** - Consider adding in future update (very new field)

---

## Testing Recommendations

After implementing changes:

1. **Test Nostrum struct conversion:** Ensure `new/1` still works correctly with
   Nostrum.Struct.Guild.Role
2. **Test field access:** Verify all fields are accessible and have correct
   default values
3. **Test with nil values:** Ensure optional fields handle nil correctly
4. **Check Nostrum version:** Verify which fields are actually available in the
   current Nostrum version

---

## Conclusion

The Role payload needs **7 corrections**:

- 2 nullability fixes (icon, unicode_emoji) - **HIGH PRIORITY**
- 2 missing required fields (flags) - **MEDIUM PRIORITY**
- 1 missing optional field (tags) - **MEDIUM PRIORITY**
- 2 documentation improvements (id, permissions) - **LOW PRIORITY**

All recommended changes maintain backwards compatibility with existing code
while ensuring compliance with the Discord API specification.
