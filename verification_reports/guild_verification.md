# Guild Payload Verification Report

Generated: 2025-10-05

## Summary

This report compares the Guild payload TypedStruct in
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/guild.ex`
against the official Discord API Guild Object structure (v10) and the TypeScript
definitions from discord-api-types.

### Key Findings

- **Total Discord API Fields (including inherited)**: 51 fields (including
  GUILD_CREATE specific fields)
- **Current Implementation Fields**: 46 fields
- **Missing Fields**: 9 fields
- **Type Corrections Needed**: 1 field (`threads` should be `:map` not
  `{:array, :map}`)
- **Nullability Corrections Needed**: 16 fields (need `allow_nil?: true`)
- **Deprecated Fields**: 1 field (`region` - correctly included but deprecated)

**Important Note**: Nostrum converts Discord's array fields (`roles`,
`channels`, `threads`) into maps indexed by ID. The current `:map` type for
`roles` and `channels` is correct.

## Quick Reference: Issues Summary

### Type Corrections (1 field)

- `threads`: Change from `{:array, :map}` to `:map`

### Nullability Corrections (16 fields)

Fields that need `allow_nil?: true`:

- `icon`, `splash`, `discovery_splash`
- `afk_channel_id`, `application_id`
- `widget_enabled`, `widget_channel_id`
- `system_channel_id`, `rules_channel_id`, `public_updates_channel_id`,
  `safety_alerts_channel_id`
- `unavailable`
- `vanity_url_code`, `description`, `banner`
- `premium_subscription_count`, `max_video_channel_users`,
  `max_stage_video_channel_users`
- `welcome_screen`

### Missing Fields (9 fields)

- `icon_hash`, `owner`, `permissions`
- `max_presences`
- `approximate_member_count`, `approximate_presence_count`
- `hub_type`, `incidents_data`
- GUILD_CREATE specific: `members`, `presences`, `stage_instances`,
  `soundboard_sounds`

### Deprecated Fields (1 field)

- `region`: Update description to note deprecation in favor of `rtc_region`

## Detailed Field Analysis

### Section 1: Fields with Incorrect `allow_nil?` Settings

These fields exist in our implementation but have incorrect nullability
settings.

#### 1.1 Fields That Should Have `allow_nil?: true`

| Field Name                      | Current Setting               | Should Be           | Discord API Type                   | Reason                                       |
| ------------------------------- | ----------------------------- | ------------------- | ---------------------------------- | -------------------------------------------- |
| `icon`                          | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `splash`                        | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `discovery_splash`              | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `owner_id`                      | `allow_nil?: false` (default) | `allow_nil?: false` | `Snowflake`                        | **CORRECT** - Required field                 |
| `afk_channel_id`                | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `afk_timeout`                   | `allow_nil?: false` (default) | `allow_nil?: false` | Limited integer set                | **CORRECT** - Required field                 |
| `verification_level`            | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildVerificationLevel`           | **CORRECT** - Required field                 |
| `default_message_notifications` | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildDefaultMessageNotifications` | **CORRECT** - Required field                 |
| `explicit_content_filter`       | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildExplicitContentFilter`       | **CORRECT** - Required field                 |
| `roles`                         | `allow_nil?: false` (default) | `allow_nil?: false` | `APIRole[]`                        | **CORRECT** - Required array                 |
| `emojis`                        | `allow_nil?: false` (default) | `allow_nil?: false` | `APIEmoji[]`                       | **CORRECT** - Required array                 |
| `features`                      | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildFeature[]`                   | **CORRECT** - Required array                 |
| `mfa_level`                     | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildMFALevel`                    | **CORRECT** - Required field                 |
| `application_id`                | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `widget_enabled`                | `allow_nil?: false` (default) | `allow_nil?: true`  | `boolean?`                         | Optional field                               |
| `widget_channel_id`             | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake? \| null`               | Optional AND nullable                        |
| `system_channel_id`             | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `system_channel_flags`          | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildSystemChannelFlags`          | **CORRECT** - Required field                 |
| `rules_channel_id`              | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `public_updates_channel_id`     | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `safety_alerts_channel_id`      | `allow_nil?: false` (default) | `allow_nil?: true`  | `Snowflake \| null`                | Nullable field                               |
| `joined_at`                     | `allow_nil?: false` (default) | `allow_nil?: false` | `string`                           | **CORRECT** - Required in GUILD_CREATE       |
| `large`                         | `allow_nil?: false` (default) | `allow_nil?: false` | `boolean`                          | **CORRECT** - Required in GUILD_CREATE       |
| `unavailable`                   | `allow_nil?: false` (default) | `allow_nil?: true`  | `boolean?`                         | Optional field                               |
| `member_count`                  | `allow_nil?: false` (default) | `allow_nil?: false` | `number`                           | **CORRECT** - Required in GUILD_CREATE       |
| `voice_states`                  | `allow_nil?: false` (default) | `allow_nil?: false` | `APIBaseVoiceState[]`              | **CORRECT** - Required array in GUILD_CREATE |
| `channels`                      | `allow_nil?: false` (default) | `allow_nil?: false` | `APIChannel[]`                     | **CORRECT** - Required in GUILD_CREATE       |
| `threads`                       | `allow_nil?: false` (default) | `allow_nil?: false` | `APIChannel[]`                     | **CORRECT** - Required in GUILD_CREATE       |
| `guild_scheduled_events`        | `allow_nil?: false` (default) | `allow_nil?: false` | `APIGuildScheduledEvent[]`         | **CORRECT** - Required array in GUILD_CREATE |
| `vanity_url_code`               | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `description`                   | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `banner`                        | `allow_nil?: false` (default) | `allow_nil?: true`  | `string \| null`                   | Nullable field                               |
| `premium_tier`                  | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildPremiumTier`                 | **CORRECT** - Required field                 |
| `premium_subscription_count`    | `allow_nil?: false` (default) | `allow_nil?: true`  | `number?`                          | Optional field                               |
| `preferred_locale`              | `allow_nil?: false` (default) | `allow_nil?: false` | `Locale`                           | **CORRECT** - Required with default "en-US"  |
| `max_video_channel_users`       | `allow_nil?: false` (default) | `allow_nil?: true`  | `number?`                          | Optional field                               |
| `max_stage_video_channel_users` | `allow_nil?: false` (default) | `allow_nil?: true`  | `number?`                          | Optional field                               |
| `welcome_screen`                | `allow_nil?: false` (default) | `allow_nil?: true`  | `APIGuildWelcomeScreen?`           | Optional field (from APIPartialGuild)        |
| `nsfw_level`                    | `allow_nil?: false` (default) | `allow_nil?: false` | `GuildNSFWLevel`                   | **CORRECT** - Required field                 |
| `stickers`                      | `allow_nil?: false` (default) | `allow_nil?: false` | `APISticker[]`                     | **CORRECT** - Required array                 |
| `premium_progress_bar_enabled`  | `allow_nil?: false` (default) | `allow_nil?: false` | `boolean`                          | **CORRECT** - Required field                 |

#### 1.2 Fields with Type Issues

**UPDATE**: After verifying Nostrum's documentation, the current types are
**CORRECT**:

| Field Name | Current Type     | Discord API Type | Nostrum Type                                 | Status                                               |
| ---------- | ---------------- | ---------------- | -------------------------------------------- | ---------------------------------------------------- |
| `roles`    | `:map`           | `APIRole[]`      | Map of Role IDs to Role objects              | ✅ **CORRECT** - Nostrum converts array to map       |
| `channels` | `:map`           | `APIChannel[]`   | Map of Channel IDs to Channel objects        | ✅ **CORRECT** - Nostrum converts array to map       |
| `threads`  | `{:array, :map}` | `APIChannel[]`   | Map of Channel IDs to Thread Channel objects | ⚠️ **Should be `:map`** - Nostrum uses map not array |

**Action Required**: Change `threads` from `{:array, :map}` to `:map` to match
Nostrum's structure.

### Section 2: Missing Fields from Discord API

These fields are defined in the Discord API but missing from our implementation.

#### 2.1 Core Guild Fields (APIGuild)

```elixir
# Add after line 18 (icon field):
field :icon_hash, :string,
  allow_nil?: true,
  description: "Icon hash, returned when in the template object"

# Add after line 62 (discovery_splash field):
field :owner, :boolean,
  allow_nil?: true,
  description: "True if the user is the owner of the guild (only from get-current-user-guilds endpoint)"

field :permissions, :string,
  allow_nil?: true,
  description: "Total permissions for the user in the guild (only from get-current-user-guilds endpoint)"

# Add after line 65 (max_members field):
field :max_presences, :integer,
  allow_nil?: true,
  description: "The maximum number of presences for the guild (null is always returned, apart from the largest of guilds)"

# Add after line 69 (premium_subscription_count field):
field :approximate_member_count, :integer,
  allow_nil?: true,
  description: "Approximate number of members in this guild (returned when with_counts is true)"

field :approximate_presence_count, :integer,
  allow_nil?: true,
  description: "Approximate number of non-offline members in this guild (returned when with_counts is true)"

# Add after line 83 (premium_progress_bar_enabled field):
field :hub_type, :integer,
  allow_nil?: true,
  description: "The type of Student Hub the guild is (null for non-hub guilds)"

field :incidents_data, :map,
  allow_nil?: true,
  description: "The incidents data for this guild (invites_disabled_until, dms_disabled_until, etc.)"
```

#### 2.2 GUILD_CREATE Specific Fields

These fields are already present in the implementation and are correct:

- `joined_at` - ✅ Correct
- `large` - ✅ Correct
- `unavailable` - ✅ Correct (but needs `allow_nil?: true`)
- `member_count` - ✅ Correct
- `voice_states` - ✅ Correct
- `channels` - ✅ Correct (but type needs fixing)
- `threads` - ✅ Correct
- `guild_scheduled_events` - ✅ Correct

Missing GUILD_CREATE specific fields:

```elixir
# Add after line 56 (voice_states field):
field :members, {:array, :map},
  allow_nil?: false,
  description: "Users in the guild (GUILD_CREATE event only)"

field :presences, {:array, :map},
  allow_nil?: false,
  description: "Presences of members in the guild (GUILD_CREATE event only)"

field :stage_instances, {:array, :map},
  allow_nil?: false,
  description: "Stage instances in the guild (GUILD_CREATE event only)"

field :soundboard_sounds, {:array, :map},
  allow_nil?: false,
  description: "Soundboard sounds in the guild (GUILD_CREATE event only)"
```

### Section 3: Extra Fields (Not in Discord API)

These fields are in our implementation but not found in the Discord API
documentation. They might be legacy or Nostrum-specific.

**Note**: These fields appear to be correct for the GUILD_CREATE event
structure. No action needed.

### Section 4: Deprecated Fields

| Field Name | Status                                         | Recommendation                                  |
| ---------- | ---------------------------------------------- | ----------------------------------------------- |
| `region`   | Deprecated in favor of `rtc_region` on channel | Keep but update description to note deprecation |

**Recommended description update:**

```elixir
field :region, :string,
  allow_nil?: false,
  description: "The id of the voice region (DEPRECATED: use rtc_region on channel instead)"
```

## Recommended Changes

### Priority 1: Critical Type Corrections

**UPDATE**: After verifying Nostrum's behavior, only one type correction is
needed:

```elixir
# Line 60: Change threads from array to map
field :threads, :map,
  allow_nil?: false,
  description: "Map of thread id to thread (GUILD_CREATE event only)"
```

**Note**: The `roles` and `channels` fields are correctly typed as `:map`
because Nostrum converts Discord's arrays into maps indexed by ID for easier
lookup.

### Priority 2: Nullability Corrections

Update the following fields to allow nil:

```elixir
# Line 17
field :icon, :string,
  allow_nil?: true,
  description: "The hash of the guild's icon"

# Line 18
field :splash, :string,
  allow_nil?: true,
  description: "The hash of the guild's splash"

# Line 21
field :afk_channel_id, :integer,
  allow_nil?: true,
  description: "The id of the guild's afk channel"

# Line 34
field :application_id, :integer,
  allow_nil?: true,
  description: "Application id of the guild creator if bot created"

# Line 37
field :widget_enabled, :boolean,
  allow_nil?: true,
  description: "Whether or not the server widget is enabled"

# Line 38
field :widget_channel_id, :integer,
  allow_nil?: true,
  description: "The channel id for the server widget"

# Line 40
field :system_channel_id, :integer,
  allow_nil?: true,
  description: "The id of the channel to which system messages are sent"

# Line 43
field :rules_channel_id, :integer,
  allow_nil?: true,
  description: "The id of the channel used for rules (PUBLIC guilds only)"

# Line 46
field :public_updates_channel_id, :integer,
  allow_nil?: true,
  description: "The id of the channel where admins receive notices (PUBLIC guilds only)"

# Line 49
field :safety_alerts_channel_id, :integer,
  allow_nil?: true,
  description: "The id of the channel for safety alerts"

# Line 54
field :unavailable, :boolean,
  allow_nil?: true,
  description: "Whether the guild is unavailable due to an outage"

# Line 59
field :vanity_url_code, :string,
  allow_nil?: true,
  description: "Guild invite vanity URL"

# Line 62
field :discovery_splash, :string,
  allow_nil?: true,
  description: "The hash of the guild's discovery splash"

# Line 66
field :description, :string,
  allow_nil?: true,
  description: "The description for the guild"

# Line 67
field :banner, :string,
  allow_nil?: true,
  description: "The hash of the guild's banner"

# Line 69
field :premium_subscription_count, :integer,
  allow_nil?: true,
  description: "Number of boosts this guild has"

# Line 74
field :max_video_channel_users, :integer,
  allow_nil?: true,
  description: "Max amount of users in a video channel"

# Line 77
field :max_stage_video_channel_users, :integer,
  allow_nil?: true,
  description: "Max amount of users in a stage video channel"

# Line 80
field :welcome_screen, :map,
  allow_nil?: true,
  description: "The welcome screen configuration"
```

### Priority 3: Add Missing Fields

Add these missing fields from the Discord API:

```elixir
# After icon field (line ~17)
field :icon_hash, :string,
  allow_nil?: true,
  description: "Icon hash, returned when in the template object"

# After discovery_splash field (line ~62)
field :owner, :boolean,
  allow_nil?: true,
  description: "True if the user is the owner of the guild (only from get-current-user-guilds endpoint)"

field :permissions, :string,
  allow_nil?: true,
  description: "Total permissions for the user in the guild (only from get-current-user-guilds endpoint)"

# After max_members field (line ~65)
field :max_presences, :integer,
  allow_nil?: true,
  description: "The maximum number of presences for the guild (null is always returned, apart from the largest of guilds)"

# After premium_subscription_count field (line ~69)
field :approximate_member_count, :integer,
  allow_nil?: true,
  description: "Approximate number of members in this guild (returned when with_counts is true)"

field :approximate_presence_count, :integer,
  allow_nil?: true,
  description: "Approximate number of non-offline members in this guild (returned when with_counts is true)"

# After premium_progress_bar_enabled field (line ~83)
field :hub_type, :integer,
  allow_nil?: true,
  description: "The type of Student Hub the guild is (null for non-hub guilds)"

field :incidents_data, :map,
  allow_nil?: true,
  description: "The incidents data for this guild (invites_disabled_until, dms_disabled_until, etc.)"

# After voice_states field (line ~56)
field :members, {:array, :map},
  allow_nil?: false,
  description: "Users in the guild (GUILD_CREATE event only)"

field :presences, {:array, :map},
  allow_nil?: false,
  description: "Presences of members in the guild (GUILD_CREATE event only)"

field :stage_instances, {:array, :map},
  allow_nil?: false,
  description: "Stage instances in the guild (GUILD_CREATE event only)"

field :soundboard_sounds, {:array, :map},
  allow_nil?: false,
  description: "Soundboard sounds in the guild (GUILD_CREATE event only)"
```

### Priority 4: Update Deprecated Field

```elixir
# Line 20
field :region, :string,
  allow_nil?: false,
  description: "The id of the voice region (DEPRECATED: use rtc_region on channel instead)"
```

## Notes on Discord API Conventions

Based on the discord-api-types definitions:

1. **Optional vs Nullable**:

   - `field?` (with `?` after field name) = optional field, may not be present
   - `| null` (union with null type) = nullable field, present but can be null
   - `field?: Type | null` = both optional AND nullable

2. **In Elixir TypedStruct**:

   - Optional fields should have `allow_nil?: true`
   - Nullable fields should have `allow_nil?: true`
   - Required non-nullable fields should have `allow_nil?: false` (or omit, as
     false is default)

3. **GUILD_CREATE Event**:

   - Receives all fields from `APIGuild` plus additional fields
   - Additional fields: `joined_at`, `large`, `unavailable?`, `member_count`,
     `voice_states`, `members`, `channels`, `threads`, `presences`,
     `stage_instances`, `guild_scheduled_events`, `soundboard_sounds`

4. **Arrays vs Maps (Nostrum-Specific)**:
   - Discord API returns arrays of objects (e.g., `APIRole[]`, `APIEmoji[]`)
   - **Nostrum Conversion**: Nostrum converts certain arrays to maps indexed by
     ID:
     - `roles`: Array → Map of Role IDs to Role objects ✅
     - `channels`: Array → Map of Channel IDs to Channel objects ✅
     - `threads`: Array → Map of Channel IDs to Thread Channel objects ✅
   - Arrays that remain as arrays in Nostrum:
     - `emojis`: List of Emoji objects (stays as array)
     - `voice_states`: List of voice state maps (stays as array)
     - `features`: List of strings (stays as array)
     - `stickers`: List of sticker objects (stays as array)
     - `guild_scheduled_events`: List of event objects (stays as array)

## References

- **Discord API Documentation**:
  https://discord.com/developers/docs/resources/guild#guild-object
- **Discord API Types (v10)**:
  https://github.com/discordjs/discord-api-types/blob/main/payloads/v10/guild.ts
- **Gateway Events**:
  https://github.com/discordjs/discord-api-types/blob/main/gateway/v10.ts
- **Nostrum Documentation**:
  https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.html

## Next Steps

1. Review this report with the development team
2. Verify Nostrum's behavior for array/map conversion (roles, channels, etc.)
3. Apply Priority 1 changes (critical type corrections)
4. Apply Priority 2 changes (nullability corrections)
5. Apply Priority 3 changes (add missing fields)
6. Apply Priority 4 changes (update deprecated field)
7. Run tests to ensure compatibility with Nostrum
8. Update any code that depends on these field types
