# User Payload Verification Report

**Date**: 2025-10-05 **File**:
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/user.ex`
**Discord API Reference**:
https://discord.com/developers/docs/resources/user#user-object **Discord API
Types Reference**:
https://discord-api-types.dev/api/discord-api-types-v10/interface/APIUser
**Nostrum Reference**: Nostrum.Struct.User

---

## Executive Summary

The current User payload implementation includes only 6 fields out of 20 fields
available in the Discord API User Object. The implementation correctly matches
the Nostrum.Struct.User fields, but Discord provides significantly more user
data that is not being captured.

### Current Status

- **Matching Fields**: 6 out of 6 current fields match Nostrum
- **Discord API Coverage**: 6 out of 20 fields (30%)
- **Missing Optional Fields**: 14 fields
- **Type Mismatches**: 1 field (id type)
- **allow_nil? Issues**: 4 fields need correction

---

## Field-by-Field Analysis

### ✅ Correctly Implemented Fields

#### 1. `username`

- **Current**: `field :username, :string, allow_nil?: false`
- **Discord API**: `username: string` (required, non-nullable)
- **Status**: ✅ CORRECT

#### 2. `discriminator`

- **Current**: `field :discriminator, :string, allow_nil?: false`
- **Discord API**: `discriminator: string` (required, non-nullable)
- **Status**: ✅ CORRECT

### ⚠️ Fields Needing Corrections

#### 3. `id`

- **Current**: `field :id, :integer, allow_nil?: false`
- **Discord API**: `id: string` (required, non-nullable)
- **Nostrum**: `id: Snowflake.t()` (which is an integer)
- **Issue**: Type mismatch - Discord uses string for snowflake IDs
- **Status**: ⚠️ ACCEPTABLE (Nostrum converts to integer, but technically
  incorrect per API spec)
- **Recommendation**: Keep as `:integer` to match Nostrum, but document this
  conversion

#### 4. `global_name`

- **Current**: `field :global_name, :string`
- **Discord API**: `global_name: null | string` (required but nullable)
- **Issue**: Missing `allow_nil?: true` (field is nullable)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :global_name, :string,
  allow_nil?: true,
  description: "The user's display name, if it is set. For bots, this is the application name"
```

#### 5. `avatar`

- **Current**: `field :avatar, :string`
- **Discord API**: `avatar: null | string` (required but nullable)
- **Issue**: Missing `allow_nil?: true` (field is nullable)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :avatar, :string,
  allow_nil?: true,
  description: "The user's avatar hash"
```

#### 6. `bot`

- **Current**: `field :bot, :boolean`
- **Discord API**: `bot?: boolean` (optional)
- **Issue**: Missing `allow_nil?: true` (field is optional)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :bot, :boolean,
  allow_nil?: true,
  description: "Whether the user belongs to an OAuth2 application"
```

#### 7. `public_flags`

- **Current**: `field :public_flags, :integer`
- **Discord API**: `public_flags?: UserFlags` (optional)
- **Issue**: Missing `allow_nil?: true` (field is optional)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :public_flags, :integer,
  allow_nil?: true,
  description: "The public flags on a user's account (as a bitset)"
```

---

## Missing Fields from Discord API

The following fields are available in the Discord API but not currently captured
in the User payload. **Note**: These fields are NOT in Nostrum.Struct.User,
which only includes basic user fields.

### User System/OAuth Fields

#### 8. `system` (optional)

- **Discord API**: `system?: boolean`
- **Description**: Whether the user is an Official Discord System user (part of
  the urgent message system)
- **Recommended Addition**:

```elixir
field :system, :boolean,
  allow_nil?: true,
  description: "Whether the user is an Official Discord System user"
```

#### 9. `mfa_enabled` (optional)

- **Discord API**: `mfa_enabled?: boolean`
- **Description**: Whether the user has two-factor authentication enabled
- **Recommended Addition**:

```elixir
field :mfa_enabled, :boolean,
  allow_nil?: true,
  description: "Whether the user has two factor enabled on their account"
```

### User Appearance Fields

#### 10. `banner` (optional, nullable)

- **Discord API**: `banner?: null | string`
- **Description**: The user's banner hash
- **Recommended Addition**:

```elixir
field :banner, :string,
  allow_nil?: true,
  description: "The user's banner hash"
```

#### 11. `accent_color` (optional, nullable)

- **Discord API**: `accent_color?: null | number`
- **Description**: The user's banner color encoded as an integer
- **Recommended Addition**:

```elixir
field :accent_color, :integer,
  allow_nil?: true,
  description: "The user's banner color encoded as an integer representation of hexadecimal color code"
```

#### 12. `avatar_decoration` (optional, nullable, DEPRECATED)

- **Discord API**: `avatar_decoration?: null | string` (deprecated)
- **Description**: The user's avatar decoration hash (deprecated in favor of
  avatar_decoration_data)
- **Recommended Addition**: SKIP - deprecated field

#### 13. `avatar_decoration_data` (optional, nullable)

- **Discord API**: `avatar_decoration_data?: null | APIAvatarDecorationData`
- **Description**: The data for the user's avatar decoration
- **Note**: This is a nested object type
- **Recommended Addition**:

```elixir
field :avatar_decoration_data, :map,
  allow_nil?: true,
  description: "The data for the user's avatar decoration"
```

### User Account Settings Fields

#### 14. `locale` (optional)

- **Discord API**: `locale?: string`
- **Description**: The user's chosen language option
- **Recommended Addition**:

```elixir
field :locale, :string,
  allow_nil?: true,
  description: "The user's chosen language option"
```

#### 15. `email` (optional, nullable)

- **Discord API**: `email?: null | string`
- **Description**: The user's email (requires OAuth2 email scope)
- **Recommended Addition**:

```elixir
field :email, :string,
  allow_nil?: true,
  description: "The user's email (requires OAuth2 email scope)"
```

#### 16. `verified` (optional)

- **Discord API**: `verified?: boolean`
- **Description**: Whether the email has been verified (requires OAuth2 email
  scope)
- **Recommended Addition**:

```elixir
field :verified, :boolean,
  allow_nil?: true,
  description: "Whether the email on this account has been verified (requires OAuth2 email scope)"
```

### User Subscription/Premium Fields

#### 17. `flags` (optional)

- **Discord API**: `flags?: UserFlags`
- **Description**: The flags on a user's account (similar to public_flags but
  includes private flags)
- **Recommended Addition**:

```elixir
field :flags, :integer,
  allow_nil?: true,
  description: "The flags on a user's account (as a bitset)"
```

#### 18. `premium_type` (optional)

- **Discord API**: `premium_type?: UserPremiumType`
- **Description**: The type of Nitro subscription on a user's account
- **Recommended Addition**:

```elixir
field :premium_type, :integer,
  allow_nil?: true,
  description: "The type of Nitro subscription on a user's account (0 = None, 1 = Nitro Classic, 2 = Nitro, 3 = Nitro Basic)"
```

### User Collectibles/Guild Fields (New/Extended Features)

#### 19. `collectibles` (optional, nullable)

- **Discord API**: `collectibles?: null | APICollectibles`
- **Description**: The data for the user's collectibles
- **Note**: This is a nested object type for Discord's collectibles feature
- **Recommended Addition**:

```elixir
field :collectibles, :map,
  allow_nil?: true,
  description: "The data for the user's collectibles"
```

#### 20. `primary_guild` (optional, nullable)

- **Discord API**: `primary_guild?: null | APIUserPrimaryGuild`
- **Description**: The user's primary guild
- **Note**: This is a nested object type
- **Recommended Addition**:

```elixir
field :primary_guild, :map,
  allow_nil?: true,
  description: "The user's primary guild data"
```

---

## Extra Fields Analysis

**No extra fields found.** All current fields exist in both the Discord API and
Nostrum.Struct.User.

---

## Recommended Changes

### Priority 1: Fix Existing Fields (REQUIRED)

These corrections ensure the existing fields properly handle nil values:

```elixir
defmodule AshDiscord.Consumer.Payloads.User do
  @moduledoc """
  TypedStruct wrapper for Discord User data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.User.t()`.

  ## References
  - [Discord API - User](https://discord.com/developers/docs/resources/user#user-object)
  - [Nostrum - User](https://hexdocs.pm/nostrum/Nostrum.Struct.User.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The user's id"
    field :username, :string, allow_nil?: false, description: "The user's username, not unique across the platform"

    field :discriminator, :string,
      allow_nil?: false,
      description: "The user's 4-digit discord-tag"

    field :global_name, :string,
      allow_nil?: true,
      description: "The user's display name, if it is set. For bots, this is the application name"

    field :avatar, :string,
      allow_nil?: true,
      description: "The user's avatar hash"

    field :bot, :boolean,
      allow_nil?: true,
      description: "Whether the user belongs to an OAuth2 application"

    field :public_flags, :integer,
      allow_nil?: true,
      description: "The public flags on a user's account (as a bitset)"
  end

  # ... rest of implementation
end
```

### Priority 2: Add Extended Fields (OPTIONAL)

If you want to capture the full Discord API User Object data beyond what Nostrum
provides:

```elixir
typed_struct do
  # Core fields (Priority 1 - from Nostrum)
  field :id, :integer, allow_nil?: false, description: "The user's id"
  field :username, :string, allow_nil?: false, description: "The user's username, not unique across the platform"
  field :discriminator, :string, allow_nil?: false, description: "The user's 4-digit discord-tag"
  field :global_name, :string, allow_nil?: true, description: "The user's display name, if it is set. For bots, this is the application name"
  field :avatar, :string, allow_nil?: true, description: "The user's avatar hash"
  field :bot, :boolean, allow_nil?: true, description: "Whether the user belongs to an OAuth2 application"
  field :public_flags, :integer, allow_nil?: true, description: "The public flags on a user's account (as a bitset)"

  # System/OAuth fields
  field :system, :boolean, allow_nil?: true, description: "Whether the user is an Official Discord System user"
  field :mfa_enabled, :boolean, allow_nil?: true, description: "Whether the user has two factor enabled on their account"

  # Appearance fields
  field :banner, :string, allow_nil?: true, description: "The user's banner hash"
  field :accent_color, :integer, allow_nil?: true, description: "The user's banner color encoded as an integer representation of hexadecimal color code"
  field :avatar_decoration_data, :map, allow_nil?: true, description: "The data for the user's avatar decoration"

  # Account settings fields
  field :locale, :string, allow_nil?: true, description: "The user's chosen language option"
  field :email, :string, allow_nil?: true, description: "The user's email (requires OAuth2 email scope)"
  field :verified, :boolean, allow_nil?: true, description: "Whether the email on this account has been verified (requires OAuth2 email scope)"

  # Premium/flags fields
  field :flags, :integer, allow_nil?: true, description: "The flags on a user's account (as a bitset)"
  field :premium_type, :integer, allow_nil?: true, description: "The type of Nitro subscription (0 = None, 1 = Nitro Classic, 2 = Nitro, 3 = Nitro Basic)"

  # Extended features
  field :collectibles, :map, allow_nil?: true, description: "The data for the user's collectibles"
  field :primary_guild, :map, allow_nil?: true, description: "The user's primary guild data"
end
```

### Priority 3: Update .new() Function (IF adding extended fields)

If you add the extended fields, you'll need to update the `new/1` function to
handle fields that don't exist in Nostrum:

```elixir
def new(%Nostrum.Struct.User{} = nostrum_user) do
  # Nostrum only provides the basic fields, so extended fields will be nil
  # You would need to fetch these from Discord API separately if needed
  super(Map.from_struct(nostrum_user))
end

# Alternative: Accept raw Discord payload with extended fields
def new(%{id: _} = discord_payload) when is_map(discord_payload) do
  super(discord_payload)
end
```

---

## Discord API Nullable vs Optional Semantics

Understanding Discord's field markings:

1. **`field?` (optional field)**: May not be present in the response →
   `allow_nil?: true`
2. **`?type` (nullable type)**: Present but may be null → `allow_nil?: true`
3. **`field? ?type` (both)**: May not be present OR may be null →
   `allow_nil?: true`
4. **`field type` (neither)**: Always present and non-null → `allow_nil?: false`

---

## Recommendations Summary

### Immediate Actions (Required)

1. ✅ Add `allow_nil?: true` to `global_name` field
2. ✅ Add `allow_nil?: true` to `avatar` field
3. ✅ Add `allow_nil?: true` to `bot` field
4. ✅ Add `allow_nil?: true` to `public_flags` field

### Consider for Future (Optional)

1. Decide if you want to capture extended Discord API fields not in Nostrum
2. If yes, add the 14 missing optional fields
3. Update the `.new()` function to handle Discord API payloads with extended
   fields
4. Document the difference between "Nostrum-compatible" fields vs "full Discord
   API" fields

### Notes

- The current implementation correctly matches Nostrum.Struct.User
- Nostrum intentionally provides a minimal User struct with only basic fields
- Many Discord API fields (email, locale, premium_type, etc.) are only available
  via OAuth2 scopes
- The extended fields may not be present in gateway events, only in specific API
  responses

---

## Testing Recommendations

1. **Test nil handling**: Verify that fields marked `allow_nil?: true` properly
   handle nil values
2. **Test Nostrum compatibility**: Ensure `new(%Nostrum.Struct.User{})` still
   works correctly
3. **Test missing fields**: Verify behavior when Discord doesn't send optional
   fields
4. **Test null vs missing**: Verify behavior when Discord sends `null` vs not
   including the field

---

## References

- Discord API Documentation:
  https://discord.com/developers/docs/resources/user#user-object
- Discord API Types (TypeScript):
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APIUser
- Nostrum User Struct: https://hexdocs.pm/nostrum/Nostrum.Struct.User.html
- Nostrum Source:
  `/home/joba/sandbox/ash_discord/deps/nostrum/lib/nostrum/struct/user.ex`
