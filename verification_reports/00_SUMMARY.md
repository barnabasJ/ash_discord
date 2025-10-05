# Discord Payload Verification Summary

Complete verification of all payload types against Discord API documentation.

## Verification Process

Each payload type was verified by:

1. Reading the current TypedStruct implementation
2. Fetching official Discord API documentation using links from module
   `@moduledoc`
3. Comparing field names, types, and nullability settings
4. Checking for missing or extra fields
5. Generating detailed reports with exact code snippets for fixes

## Discord API Nullability Rules

Based on Discord API v10+ documentation:

- **`field?`** → Optional (may be omitted) → requires `allow_nil?: true`
- **`?Type`** → Nullable (present but can be null) → requires `allow_nil?: true`
- **`field? ?Type`** → Optional and nullable → requires `allow_nil?: true`
- **`field Type`** → Required and non-null → `allow_nil?: false` (or omit for
  default)

## Summary by Payload Type

### 1. Message ✅ Structurally Correct

**File**: `lib/ash_discord/consumer/payloads/message.ex` **Report**:
`verification_reports/message_verification.md`

- **Status**: 15 fields need `allow_nil?: true` corrections
- **Compliance**: 51.6% (16/31 fields have explicit nil handling)
- **Type Issues**: None
- **Missing Fields**: None
- **Priority**: High (frequently nil fields like `guild_id`, `edited_timestamp`,
  `webhook_id`)

### 2. User ⚠️ Needs Corrections

**File**: `lib/ash_discord/consumer/payloads/user.ex` **Report**:
`verification_reports/user_verification.md`

- **Status**: 4 fields need `allow_nil?: true`
- **Type Issues**: None
- **Missing Fields**: 14 optional Discord API fields (OAuth2 scopes, premium
  features)
- **Key Issues**: `global_name`, `avatar`, `bot`, `public_flags` all need
  `allow_nil?: true`

### 3. Guild ⚠️ Critical Type Issue

**File**: `lib/ash_discord/consumer/payloads/guild.ex` **Report**:
`verification_reports/guild_verification.md`

- **Status**: 1 critical type issue + 16 nullability issues
- **Critical**: `threads` should be `:map` not `{:array, :map}` (Nostrum
  converts to map)
- **Missing Fields**: 9 fields (`icon_hash`, `owner`, `permissions`, metrics,
  newer features)
- **Type Issues**: `threads` field type incorrect

### 4. Channel ⚠️ Many Corrections Needed

**File**: `lib/ash_discord/consumer/payloads/channel.ex` **Report**:
`verification_reports/channel_verification.md`

- **Status**: 28 fields need `allow_nil?: true`
- **Missing Fields**: 4 (`nsfw`, `managed`, `flags`, `total_message_sent`)
- **Extra Fields**: 1 (`newly_created` - may be Nostrum-specific)
- **Type Issues**: None

### 5. Member ❌ Critical Type Errors

**File**: `lib/ash_discord/consumer/payloads/member.ex` **Report**:
`verification_reports/member_verification.md`

- **Status**: 2 critical type errors
- **Critical Issues**:
  - `premium_since` typed as `:integer` but should be `:utc_datetime`
  - `communication_disabled_until` typed as `:integer` but should be
    `:utc_datetime`
- **Missing Fields**: 2 (`banner`, `avatar_decoration_data` - not yet in
  Nostrum)
- **Priority**: URGENT - will cause runtime errors

### 6. Role ⚠️ Missing Modern Fields

**File**: `lib/ash_discord/consumer/payloads/role.ex` **Report**:
`verification_reports/role_verification.md`

- **Status**: 2 nullability issues + 3 missing fields
- **Nullability**: `icon`, `unicode_emoji` need `allow_nil?: true`
- **Missing Fields**: `flags`, `tags`, `colors`
- **Type Issues**: None

### 7. Emoji ❌ Critical Type Errors

**File**: `lib/ash_discord/consumer/payloads/emoji.ex` **Report**:
`verification_reports/emoji_verification.md`

- **Status**: 2 critical type errors + 6 nullability issues
- **Critical Issues**:
  - `id` should be `:string` not `:integer` (Discord uses string snowflakes)
  - `roles` should be `{:array, :string}` not `{:array, :integer}`
- **Nullability**: All 8 fields need corrections
- **Priority**: URGENT - snowflake type mismatch

### 8. Sticker ⚠️ Type Corrections Needed

**File**: `lib/ash_discord/consumer/payloads/sticker.ex` **Report**:
`verification_reports/sticker_verification.md`

- **Status**: 2 type issues + 8 nullability issues + 1 missing field
- **Type Issues**:
  - `type` should be `:atom` not `:integer` (Nostrum converts enums)
  - `format_type` should be `:atom` not `:integer` (Nostrum converts enums)
- **Missing Fields**: `asset` (deprecated but still in spec)
- **Nullability**: 8 fields need corrections

### 9. MessageAttachment ❌ Critical Type Error

**File**: `lib/ash_discord/consumer/payloads/message_attachment.ex` **Report**:
`verification_reports/message_attachment_verification.md`

- **Status**: 1 critical type error + 1 nullability issue + 7 missing fields
- **Critical**: `id` should be `:string` not `:integer` (snowflake)
- **Nullability**: `proxy_url` needs `allow_nil?: false`
- **Missing Fields**: 7 (`description`, `title`, `ephemeral`, `duration_secs`,
  `waveform`, `flags`, `content_type`)
- **Priority**: URGENT - snowflake type mismatch

### 10. Webhook ⚠️ Missing Critical Field

**File**: `lib/ash_discord/consumer/payloads/webhook.ex` **Report**:
`verification_reports/webhook_verification.md`

- **Status**: 1 missing critical field + 10 nullability issues
- **Missing Fields**: `type` (required, non-nullable - critical for
  understanding webhook behavior)
- **Nullability**: 10 fields need `allow_nil?: true`
- **Type Issues**: None

### 11. VoiceState ✅ Minor Corrections

**File**: `lib/ash_discord/consumer/payloads/voice_state.ex` **Report**:
`verification_reports/voice_state_verification.md`

- **Status**: 5 fields need `allow_nil?: true`
- **Type Issues**: None
- **Missing Fields**: None
- **Key Issues**: `guild_id`, `channel_id`, `member`, `self_stream`,
  `request_to_speak_timestamp`

### 12. Interaction ⚠️ Missing Modern Fields

**File**: `lib/ash_discord/consumer/payloads/interaction.ex` **Report**:
`verification_reports/interaction_verification.md`

- **Status**: 7 missing fields + 5 nullability issues + 1 deprecation
- **Missing Critical**: `app_permissions`, `entitlements`,
  `authorizing_integration_owners`
- **Deprecated**: `channel_id` (use `channel.id` instead)
- **Nullability**: 5 fields need corrections

### 13. Invite ⚠️ Missing Modern Fields

**File**: `lib/ash_discord/consumer/payloads/invite.ex` **Report**:
`verification_reports/invite_verification.md`

- **Status**: 8 nullability issues + 3 missing fields
- **Missing Fields**: `target_application`, `type`, `flags`
- **Nullability**: 8 fields need `allow_nil?: true`
- **Type Issues**: None

### 14. AutoModerationRule ✅ Minor Corrections

**File**: `lib/ash_discord/consumer/payloads/auto_moderation_rule.ex`
**Report**: `verification_reports/auto_moderation_rule_verification.md`

- **Status**: 3 fields need `allow_nil?: true`
- **Type Issues**: None
- **Missing Fields**: None
- **Key Issues**: `trigger_metadata`, `exempt_roles`, `exempt_channels`

### 15. ThreadMember ✅ Minor Corrections

**File**: `lib/ash_discord/consumer/payloads/thread_member.ex` **Report**:
`verification_reports/thread_member_verification.md`

- **Status**: 3 fields need `allow_nil?: true`
- **Type Issues**: None
- **Missing Fields**: 1 (`member` - intentionally omitted, not in Nostrum)
- **Key Issues**: `id`, `user_id`, `guild_id`

## Priority Summary

### 🚨 URGENT - Critical Type Errors (Must Fix First)

1. **Member**: DateTime fields typed as integers
2. **Emoji**: Snowflake IDs typed as integers instead of strings
3. **MessageAttachment**: Snowflake ID typed as integer instead of string

### ⚠️ High Priority - Type Corrections

4. **Guild**: `threads` field type incorrect
5. **Sticker**: Enum fields should be atoms not integers

### ⚠️ High Priority - Missing Critical Fields

6. **Webhook**: Missing `type` field (required)
7. **Interaction**: Missing `app_permissions`, `entitlements`,
   `authorizing_integration_owners`

### ✅ Medium Priority - Nullability Corrections

8. **Message**: 15 fields (high usage frequency)
9. **Channel**: 28 fields
10. **Guild**: 16 fields
11. **Webhook**: 10 fields
12. **Invite**: 8 fields
13. **Sticker**: 8 fields
14. **Role**: 2 fields
15. **User**: 4 fields
16. **VoiceState**: 5 fields
17. **Interaction**: 5 fields
18. **AutoModerationRule**: 3 fields
19. **ThreadMember**: 3 fields

### ℹ️ Low Priority - Optional Enhancements

- **User**: 14 extended Discord API fields (OAuth2, premium features)
- **Role**: 3 modern Discord API fields (`flags`, `tags`, `colors`)
- **Channel**: 4 modern Discord API fields
- **MessageAttachment**: 7 modern Discord API fields
- **Invite**: 3 modern Discord API fields

## Common Issues Across Payloads

### 1. Snowflake ID Type Mismatches (CRITICAL)

**Affected**: Emoji, MessageAttachment

- Discord API uses **string** for snowflake IDs (for 53-bit precision in
  JavaScript)
- Current implementation uses **integer** (following Nostrum)
- **Decision needed**: Follow Nostrum (integers) or Discord API (strings)?

### 2. Enum Type Representations

**Affected**: Sticker

- Discord API uses **integers** for enum values
- Nostrum converts to **atoms** (`:standard`, `:guild`, `:png`, `:apng`, etc.)
- Current implementation uses integers but should use atoms to match Nostrum

### 3. DateTime vs Integer for Timestamps

**Affected**: Member (CRITICAL)

- Discord API sends ISO8601 strings
- Nostrum converts to `DateTime.t()`
- Current implementation incorrectly uses `:integer`

### 4. Optional Field Nullability

**Affected**: ALL payloads

- Discord API marks optional fields with `?`
- Many fields missing `allow_nil?: true` declarations
- Can cause runtime errors when Discord omits optional fields

### 5. Nostrum Data Transformations

**Important**: Our implementation follows **Nostrum's data structure**, not raw
Discord API:

- **Snowflakes**: Nostrum converts string IDs → integers
- **Timestamps**: Nostrum converts ISO8601 strings → `DateTime.t()`
- **Enums**: Nostrum converts integer codes → atoms
- **Arrays to Maps**: Nostrum converts some arrays (roles, channels, threads) →
  maps for efficient lookup

## Recommendations

### Immediate Actions (This Week)

1. **Fix critical type errors** in Member, Emoji, MessageAttachment
2. **Add missing `type` field** to Webhook
3. **Fix `threads` type** in Guild
4. **Fix enum types** in Sticker

### Short-term Actions (This Month)

5. Add `allow_nil?: true` to all optional fields across all payloads
6. Add missing critical fields to Interaction
7. Update field descriptions to mention optionality/nullability

### Long-term Considerations

8. Decide on policy for Discord API v10+ fields not yet in Nostrum
9. Create automated verification tests based on these reports
10. Document Nostrum vs Discord API type conversion patterns

## Testing Recommendations

After implementing corrections, test with:

1. **Real Discord events** from gateway (use test bot)
2. **Edge cases**: DM messages, deleted users, optional fields omitted
3. **Nil handling**: Verify no crashes when optional fields are nil
4. **Type conversions**: Verify Nostrum → TypedStruct conversions work
5. **Backwards compatibility**: Ensure existing code still works

## Report Files

Individual detailed reports for each payload type:

- `message_verification.md` - Message payload analysis
- `user_verification.md` - User payload analysis
- `guild_verification.md` - Guild payload analysis
- `channel_verification.md` - Channel payload analysis
- `member_verification.md` - Member payload analysis (CRITICAL)
- `role_verification.md` - Role payload analysis
- `emoji_verification.md` - Emoji payload analysis (CRITICAL)
- `sticker_verification.md` - Sticker payload analysis
- `message_attachment_verification.md` - MessageAttachment analysis (CRITICAL)
- `webhook_verification.md` - Webhook payload analysis
- `voice_state_verification.md` - VoiceState payload analysis
- `interaction_verification.md` - Interaction payload analysis
- `invite_verification.md` - Invite payload analysis
- `auto_moderation_rule_verification.md` - AutoModerationRule analysis
- `thread_member_verification.md` - ThreadMember payload analysis

Each report contains:

- Field-by-field analysis
- Exact code snippets for fixes
- Discord API reference links
- Testing recommendations
- Priority classifications

---

**Generated**: 2025-10-05 **Discord API Version**: v10 **Nostrum Version**:
v0.7.0 (referenced) **Total Payloads Verified**: 15
