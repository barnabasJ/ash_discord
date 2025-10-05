# Invite Payload Verification Report

**Date:** 2025-10-05 **File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/invite.ex`
**Discord API Reference:**
https://discord.com/developers/docs/resources/invite#invite-object **Nostrum
Reference:** https://hexdocs.pm/nostrum/Nostrum.Struct.Invite.html

## Summary

This report compares the AshDiscord Invite payload implementation against the
Discord API Invite Object structure (both base APIInvite and
APIExtendedInvite/metadata fields) and Nostrum's Invite struct.

## Field-by-Field Analysis

### ✅ Correct Fields

These fields are correctly implemented with proper types and nullability:

1. **`code`** - ✅ Correct

   - Type: `:string` (Discord: `string`, Nostrum: `String.t`)
   - Nullability: `allow_nil?: false` (Discord: required field)
   - Description: Matches

2. **`approximate_presence_count`** - ✅ Correct

   - Type: `:integer` (Discord: `number`, Nostrum: `integer | nil`)
   - Nullability: Implicit `allow_nil?: true` (Discord: optional field)
   - Description: Matches

3. **`approximate_member_count`** - ✅ Correct

   - Type: `:integer` (Discord: `number`, Nostrum: `integer | nil`)
   - Nullability: Implicit `allow_nil?: true` (Discord: optional field)
   - Description: Matches

4. **`uses`** - ✅ Correct

   - Type: `:integer` (Discord: `number`, Nostrum: `integer`)
   - Description: Matches (from metadata/extended invite)

5. **`max_uses`** - ✅ Correct

   - Type: `:integer` (Discord: `number`, Nostrum: `integer`)
   - Description: Matches (from metadata/extended invite)

6. **`max_age`** - ✅ Correct

   - Type: `:integer` (Discord: `number`, Nostrum: `integer`)
   - Description: Matches (from metadata/extended invite)

7. **`temporary`** - ✅ Correct

   - Type: `:boolean` (Discord: `boolean`, Nostrum: `boolean`)
   - Description: Matches (from metadata/extended invite)

8. **`created_at`** - ✅ Correct

   - Type: `:string` (Discord: `string`, Nostrum: `String.t`)
   - Description: Matches (from metadata/extended invite)

9. **`stage_instance`** - ✅ Correct

   - Type: `:map` (Discord: `APIInviteStageInstance`, Nostrum: not present but
     valid)
   - Nullability: Implicit `allow_nil?: true` (Discord: optional field)
   - Note: This field is deprecated in Discord API but still present

10. **`guild_scheduled_event`** - ✅ Correct
    - Type: `:map` (Discord: `APIGuildScheduledEvent`)
    - Nullability: Implicit `allow_nil?: true` (Discord: optional field)

### ⚠️ Fields Needing Corrections

1. **`guild`**

   - **Current:** `field :guild, :map, description: "Partial guild object"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Optional field (`guild?`) of type `APIInviteGuild`
   - **Nostrum:** `Nostrum.Struct.Guild.t | nil`
   - **Correction:**
     ```elixir
     field :guild, :map, allow_nil?: true, description: "Partial guild object"
     ```

2. **`channel`**

   - **Current:** `field :channel, :map, description: "Partial channel object"`
   - **Issue:** Missing explicit nullability setting
   - **Discord API:** Required field but nullable
     (`channel: null | APIInviteChannel`)
   - **Nostrum:** `Nostrum.Struct.Channel.t` (required in Nostrum)
   - **Correction:**
     ```elixir
     field :channel, :map, allow_nil?: true, description: "Partial channel object"
     ```
   - **Note:** Discord API marks this as nullable to handle edge cases

3. **`inviter`**

   - **Current:**
     `field :inviter, :map, description: "User who created the invite"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Optional field (`inviter?`) of type `APIUser`
   - **Nostrum:** `Nostrum.Struct.User.t | nil`
   - **Correction:**
     ```elixir
     field :inviter, :map, allow_nil?: true, description: "User who created the invite"
     ```

4. **`target_user`**

   - **Current:**
     `field :target_user, :map, description: "Target user for this invite"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Optional field (`target_user?`) of type `APIUser`
   - **Nostrum:** `Nostrum.Struct.User.t | nil`
   - **Correction:**
     ```elixir
     field :target_user, :map, allow_nil?: true, description: "Target user for this invite"
     ```

5. **`target_type`**

   - **Current:**
     `field :target_type, :integer, description: "Type of target for this invite"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Optional field (`target_type?`) of type `InviteTargetType`
     (enum/integer)
   - **Correction:**
     ```elixir
     field :target_type, :integer, allow_nil?: true, description: "Type of target for this invite"
     ```

6. **`expires_at`**

   - **Current:**
     `field :expires_at, :string, description: "When this invite expires"`
   - **Issue:** Missing explicit nullability setting
   - **Discord API:** Optional field and nullable (`expires_at?: null | string`)
   - **Nostrum:** Not present in Nostrum struct
   - **Correction:**
     ```elixir
     field :expires_at, :string, allow_nil?: true, description: "When this invite expires"
     ```

7. **`guild_id`**

   - **Current:**
     `field :guild_id, :integer, description: "Guild ID (from events)"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Not in base Invite object, but present in events
   - **Nostrum:** Not in Nostrum.Struct.Invite (but in InviteCreate event)
   - **Correction:**
     ```elixir
     field :guild_id, :integer, allow_nil?: true, description: "Guild ID (from events)"
     ```
   - **Rationale:** Since this only comes from events and not the base object,
     it should be optional

8. **`channel_id`**
   - **Current:**
     `field :channel_id, :integer, description: "Channel ID (from events)"`
   - **Issue:** Missing explicit `allow_nil?: true`
   - **Discord API:** Not in base Invite object, but present in events
   - **Nostrum:** Not in Nostrum.Struct.Invite (but in InviteCreate event)
   - **Correction:**
     ```elixir
     field :channel_id, :integer, allow_nil?: true, description: "Channel ID (from events)"
     ```
   - **Rationale:** Since this only comes from events and not the base object,
     it should be optional

### ❌ Missing Fields from Discord API

1. **`target_application`**

   - **Discord API:** Optional field (`target_application?`) of type
     `Partial<APIApplication>`
   - **Nostrum:** Not present
   - **Description:** "The embedded application to open for this voice channel
     embedded application invite"
   - **Recommended Addition:**
     ```elixir
     field :target_application, :map, allow_nil?: true,
       description: "Embedded application for voice channel application invite"
     ```

2. **`type`**

   - **Discord API:** Required field of type `InviteType` (enum/integer)
   - **Nostrum:** Not present
   - **Description:** "The invite type"
   - **Recommended Addition:**
     ```elixir
     field :type, :integer, allow_nil?: true,
       description: "The invite type (0 = GUILD, 1 = GROUP_DM, 2 = FRIEND)"
     ```
   - **Note:** While required in Discord API v10+, mark as `allow_nil?: true`
     for backward compatibility

3. **`flags`**
   - **Discord API:** Optional field (`flags?`) of type `InviteFlags`
     (bitfield/integer)
   - **Nostrum:** Not present
   - **Description:** "The flags of the invite"
   - **Recommended Addition:**
     ```elixir
     field :flags, :integer, allow_nil?: true,
       description: "Invite flags bitfield"
     ```

### ⚠️ Deprecated/Extra Fields

1. **`target_user_type`**
   - **Current:**
     `field :target_user_type, :integer, description: "Deprecated target user type"`
   - **Status:** Correctly marked as deprecated in description
   - **Nostrum:** Present as `integer | nil`
   - **Discord API:** Not documented (deprecated)
   - **Recommendation:** Keep as-is but ensure `allow_nil?: true`
   - **Correction:**
     ```elixir
     field :target_user_type, :integer, allow_nil?: true,
       description: "Deprecated target user type (use target_type instead)"
     ```

## Complete Corrected Implementation

Here's the complete corrected `typed_struct` block with all fixes applied:

```elixir
typed_struct do
  # Required fields
  field :code, :string, allow_nil?: false, description: "Invite code"

  # Core invite fields (nullable/optional)
  field :channel, :map, allow_nil?: true, description: "Partial channel object"
  field :guild, :map, allow_nil?: true, description: "Partial guild object"
  field :inviter, :map, allow_nil?: true, description: "User who created the invite"

  # Event-specific fields (optional)
  field :guild_id, :integer, allow_nil?: true, description: "Guild ID (from events)"
  field :channel_id, :integer, allow_nil?: true, description: "Channel ID (from events)"

  # Target fields (optional)
  field :target_user, :map, allow_nil?: true, description: "Target user for this invite"
  field :target_type, :integer, allow_nil?: true, description: "Type of target for this invite"
  field :target_user_type, :integer, allow_nil?: true,
    description: "Deprecated target user type (use target_type instead)"
  field :target_application, :map, allow_nil?: true,
    description: "Embedded application for voice channel application invite"

  # Approximate counts (optional)
  field :approximate_presence_count, :integer, allow_nil?: true,
    description: "Approximate count of online members"
  field :approximate_member_count, :integer, allow_nil?: true,
    description: "Approximate count of total members"

  # Metadata fields (from extended invite)
  field :uses, :integer, allow_nil?: true,
    description: "Number of times this invite has been used"
  field :max_uses, :integer, allow_nil?: true,
    description: "Maximum number of times this invite can be used"
  field :max_age, :integer, allow_nil?: true,
    description: "Duration (in seconds) after which the invite expires"
  field :temporary, :boolean, allow_nil?: true,
    description: "Whether this invite grants temporary membership"

  # Timestamps (optional)
  field :created_at, :string, allow_nil?: true, description: "When this invite was created"
  field :expires_at, :string, allow_nil?: true, description: "When this invite expires"

  # Additional metadata (optional)
  field :stage_instance, :map, allow_nil?: true,
    description: "Stage instance data if any (deprecated)"
  field :guild_scheduled_event, :map, allow_nil?: true,
    description: "Guild scheduled event data if any"

  # New Discord API v10+ fields
  field :type, :integer, allow_nil?: true,
    description: "The invite type (0 = GUILD, 1 = GROUP_DM, 2 = FRIEND)"
  field :flags, :integer, allow_nil?: true,
    description: "Invite flags bitfield"
end
```

## Nullability Analysis

### Discord API Nullability Conventions

Discord API uses two markers for optionality:

- **`field?`** - Optional field (may not be present in response)
- **`?type`** - Nullable type (field present but value may be null)
- **`field? ?type`** - Both optional and nullable

### Recommended TypedStruct Approach

For fields from Discord API:

1. **Required, non-nullable** → `allow_nil?: false`

   - Example: `code` (always present, never null)

2. **Optional OR nullable** → `allow_nil?: true`

   - Example: `guild?` (optional), `channel: null | type` (nullable)

3. **Metadata fields** → `allow_nil?: true`

   - These only appear in extended/detailed invite responses
   - Examples: `uses`, `max_uses`, `max_age`, `temporary`, `created_at`

4. **Event-only fields** → `allow_nil?: true`
   - These come from gateway events but not REST API responses
   - Examples: `guild_id`, `channel_id`

## Compatibility Notes

### Nostrum Compatibility

The current implementation is generally compatible with Nostrum.Struct.Invite,
but:

1. Nostrum doesn't include some newer Discord API fields (`target_application`,
   `type`, `flags`)
2. Nostrum marks metadata fields as non-nullable in the extended invite type
3. Our implementation should be more permissive (allow_nil?: true) to handle
   both simple and extended invites

### Breaking Changes

Adding explicit `allow_nil?: true` to existing fields is **not a breaking
change** because:

- Fields already accepted nil values implicitly
- This just makes the behavior explicit
- No runtime behavior changes

Adding new fields (`target_application`, `type`, `flags`) is **not a breaking
change** because:

- They're optional fields
- Existing code won't break
- Only affects new API responses that include these fields

## Recommendations

1. **Immediate fixes** (High Priority):

   - Add `allow_nil?: true` to all optional/nullable fields
   - Add missing metadata field nullability

2. **Near-term additions** (Medium Priority):

   - Add `target_application`, `type`, and `flags` fields
   - These are part of modern Discord API

3. **Documentation improvements** (Low Priority):
   - Update field descriptions to mention optional/nullable status
   - Add references to Discord API v10 changes
   - Note which fields come from extended/metadata responses

## Testing Recommendations

After applying fixes, test with:

1. **Simple invite** (from GET /invites/<code>)

   - Should have: code, channel, guild
   - May lack: metadata fields, event fields

2. **Extended invite** (with metadata)

   - Should have: all base fields + uses, max_uses, created_at, etc.

3. **Invite from gateway events** (INVITE_CREATE, INVITE_DELETE)

   - Should have: guild_id, channel_id fields
   - May have: metadata fields

4. **Invites with special targets**
   - Voice channel stream invites (target_user, target_type)
   - Application invites (target_application)

## References

- Discord API Invite Object:
  https://discord.com/developers/docs/resources/invite#invite-object
- Discord API Extended Invite:
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APIExtendedInvite
- Nostrum Invite: https://hexdocs.pm/nostrum/Nostrum.Struct.Invite.html
- Nostrum InviteCreate Event:
  https://hexdocs.pm/nostrum/Nostrum.Struct.Event.InviteCreate.html
