# Guild Payload and Generator Review

**Date**: 2025-10-05 **Reviewer**: Claude Code **Files Reviewed**:

- Payload:
  `/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/guild.ex`
- Generator: `/home/joba/sandbox/ash_discord/test/support/generators/discord.ex`
  (guild/1 function)
- Verification:
  `/home/joba/sandbox/ash_discord/verification_reports/guild_verification.md`

## Executive Summary

The Guild payload and generator have been reviewed for correctness, consistency,
and alignment with the Discord API and Nostrum library. This review identifies
several critical issues requiring immediate attention and provides
recommendations for improvement.

**Overall Assessment**: ⚠️ Moderate Issues Requiring Attention

- **Payload Structure**: Missing fields, incorrect nullability, critical type
  issue with `threads`
- **Generator Coverage**: Significantly incomplete - generates only 7 of 46
  required fields
- **Data Realism**: Generator does not properly handle nullable fields or
  complex structures

## Critical Issues

### 1. ⚠️ CRITICAL: `threads` Field Type Mismatch (CONFIRMED CORRECTED)

**Status**: ✅ **RESOLVED** (per verification report)

The verification report identified that `threads` should be `:map` type
(matching how Nostrum converts arrays to maps), not `{:array, :map}`. This has
been noted as corrected.

**Current State** (line 82 in guild.ex):

```elixir
field :threads, :map, description: "Map of thread id to thread (GUILD_CREATE event only)"
```

**Verification**: ✅ Correct - Nostrum converts Discord's thread array to map
indexed by ID

### 2. ⚠️ CRITICAL: Nullable Fields Not Properly Marked

**Impact**: HIGH - May cause runtime errors when Discord returns null values

The following fields **MUST** be marked with `allow_nil?: true` but currently
default to `allow_nil?: false`:

| Field                           | Line    | Current | Required  | Reason                                    |
| ------------------------------- | ------- | ------- | --------- | ----------------------------------------- |
| `icon`                          | 17      | No nil  | Allow nil | Can be null when guild has no icon        |
| `splash`                        | 18      | No nil  | Allow nil | Can be null when guild has no splash      |
| `description`                   | 93-95   | No nil  | Allow nil | Can be null when guild has no description |
| `banner`                        | 97      | No nil  | Allow nil | Can be null when guild has no banner      |
| `discovery_splash`              | 85-87   | No nil  | Allow nil | Can be null for non-discoverable guilds   |
| `afk_channel_id`                | 22-24   | No nil  | Allow nil | Can be null when no AFK channel set       |
| `application_id`                | 38-40   | No nil  | Allow nil | Only set for bot-created guilds           |
| `widget_enabled`                | 42-44   | No nil  | Allow nil | Optional field                            |
| `widget_channel_id`             | 46-48   | No nil  | Allow nil | Optional and nullable                     |
| `system_channel_id`             | 50-52   | No nil  | Allow nil | Can be null                               |
| `rules_channel_id`              | 54-56   | No nil  | Allow nil | Can be null                               |
| `public_updates_channel_id`     | 58-60   | No nil  | Allow nil | Can be null                               |
| `safety_alerts_channel_id`      | 62-64   | No nil  | Allow nil | Can be null                               |
| `unavailable`                   | 69-71   | No nil  | Allow nil | Optional field                            |
| `vanity_url_code`               | 78-80   | No nil  | Allow nil | Can be null                               |
| `premium_subscription_count`    | 100-102 | No nil  | Allow nil | Optional field                            |
| `max_video_channel_users`       | 107-109 | No nil  | Allow nil | Optional field                            |
| `max_stage_video_channel_users` | 111-113 | No nil  | Allow nil | Optional field                            |
| `welcome_screen`                | 115-117 | No nil  | Allow nil | Optional field                            |

**Recommendation**: Update all fields listed above to include `allow_nil?: true`

### 3. ⚠️ CRITICAL: Generator Missing Critical Collections

**Impact**: HIGH - Tests cannot properly simulate GUILD_CREATE events

The generator does not generate the following **required** collections that are
always present in GUILD_CREATE events:

| Field                    | Type             | Status     | Impact                                 |
| ------------------------ | ---------------- | ---------- | -------------------------------------- |
| `roles`                  | `:map`           | ❌ Missing | Cannot test role-based functionality   |
| `channels`               | `:map`           | ❌ Missing | Cannot test channel relationships      |
| `emojis`                 | `{:array, :map}` | ❌ Missing | Cannot test custom emoji functionality |
| `voice_states`           | `{:array, :map}` | ❌ Missing | Cannot test voice state tracking       |
| `threads`                | `:map`           | ❌ Missing | Cannot test thread functionality       |
| `stickers`               | `{:array, :map}` | ❌ Missing | Cannot test custom stickers            |
| `guild_scheduled_events` | `{:array, :map}` | ❌ Missing | Cannot test scheduled events           |

**Current Generator Output**:

```elixir
def guild(attrs \\ %{}) do
  defaults = %{
    id: generate_snowflake(),
    name: "#{Faker.Person.first_name()}'s #{Faker.Util.pick(["Server", "Guild", "Community"])}",
    icon: Faker.UUID.v4(),  # ❌ Never generates nil
    description: Faker.Lorem.sentence(5..20),  # ❌ Never generates nil
    owner_id: generate_snowflake(),
    region: "us-east",
    verification_level: 0,
    default_message_notifications: 0,
    explicit_content_filter: 0,
    features: [],
    mfa_level: 0,
    member_count: Faker.random_between(10, 1000)
    # ❌ Missing 39+ fields
  }

  struct(Nostrum.Struct.Guild, merge_attrs(defaults, attrs))
end
```

**Recommendation**: Add comprehensive field generation (see Recommended
Generator Updates section)

## Medium Priority Issues

### 4. ⚠️ Generator Does Not Handle Nullable Fields

**Impact**: MEDIUM - Tests never exercise nil-handling code paths

Fields that should **sometimes** be nil are **always** generated with values:

| Field              | Current Behavior | Should Be                        |
| ------------------ | ---------------- | -------------------------------- |
| `icon`             | Always UUID      | Sometimes nil (e.g., 40% chance) |
| `description`      | Always sentence  | Sometimes nil (e.g., 30% chance) |
| `banner`           | Not generated    | Sometimes nil (e.g., 70% chance) |
| `splash`           | Not generated    | Sometimes nil (e.g., 80% chance) |
| `discovery_splash` | Not generated    | Sometimes nil (e.g., 90% chance) |
| `afk_channel_id`   | Not generated    | Sometimes nil (e.g., 50% chance) |
| `vanity_url_code`  | Not generated    | Sometimes nil (e.g., 90% chance) |

**Example Pattern**:

```elixir
# ❌ Current - always has icon
icon: Faker.UUID.v4()

# ✅ Should be - sometimes nil
icon: if(Faker.Util.pick([true, true, true, false]), do: Faker.UUID.v4(), else: nil)
```

### 5. ⚠️ Missing GUILD_CREATE Specific Fields

**Impact**: MEDIUM - Cannot fully test GUILD_CREATE event handling

The payload includes these GUILD_CREATE-specific fields, but the generator
doesn't populate them:

| Field         | Required for GUILD_CREATE | Generator Status |
| ------------- | ------------------------- | ---------------- |
| `joined_at`   | Yes                       | ❌ Missing       |
| `large`       | Yes                       | ❌ Missing       |
| `unavailable` | Optional                  | ❌ Missing       |

### 6. ⚠️ Missing Fields from Discord API

**Impact**: LOW to MEDIUM - Incomplete coverage of Discord API

The verification report identified 9 missing fields that should be added to the
payload:

**Core Guild Fields**:

- `icon_hash` - Icon hash for template objects
- `owner` - Boolean flag for guild ownership
- `permissions` - User permissions string
- `max_presences` - Maximum presences (usually null)
- `approximate_member_count` - Approximate member count
- `approximate_presence_count` - Approximate presence count
- `hub_type` - Student Hub type
- `incidents_data` - Incident data map

**GUILD_CREATE Specific**:

- `members` - Array of member maps
- `presences` - Array of presence maps
- `stage_instances` - Array of stage instance maps
- `soundboard_sounds` - Array of soundboard sound maps

**Note**: These are lower priority as they may not be used in the current
application, but should be added for API completeness.

## Low Priority Issues

### 7. ℹ️ Deprecated Field Usage

**Impact**: LOW - Still functional but deprecated

The `region` field is deprecated in favor of `rtc_region` on channel objects.

**Current** (line 20):

```elixir
field :region, :string, description: "The id of the voice region"
```

**Recommended**:

```elixir
field :region, :string,
  description: "The id of the voice region (DEPRECATED: use rtc_region on channel instead)"
```

### 8. ℹ️ Generator Does Not Match Real-World Distributions

**Impact**: LOW - Tests may not catch edge cases

Current generator creates unrealistic data distributions:

- All guilds have exact same feature set (empty features list)
- All guilds use same region ("us-east")
- Member count always 10-1000 (no small/mega guilds)
- All verification/filter levels set to 0
- No variation in MFA requirements

## Specific Concerns from Review Request

### ✅ `threads` field type

**Status**: Verified as corrected to `:map` type

### ✅ Nullable fields (`icon`, `splash`, `banner`, `description`)

**Status**: **ISSUE CONFIRMED**

- Payload: Not marked as `allow_nil?: true`
- Generator: Always generates values, never nil

### ✅ `roles` and `channels` should be maps

**Status**: **CORRECT** in payload (`:map` type)

- Generator: **MISSING** - does not generate these fields

### ✅ Missing `emojis` and `voice_states` in generator

**Status**: **ISSUE CONFIRMED**

- Payload: Correctly defined as `{:array, :map}`
- Generator: **MISSING** - does not generate these collections

## Recommended Generator Updates

### High Priority: Add Critical Collections

```elixir
def guild(attrs \\ %{}) do
  # Generate a guild ID to use for related entities
  guild_id = generate_snowflake()

  defaults = %{
    id: guild_id,
    name: "#{Faker.Person.first_name()}'s #{Faker.Util.pick(["Server", "Guild", "Community"])}",

    # Nullable fields - sometimes nil
    icon: if(Faker.Util.pick([true, true, true, false]), do: Faker.UUID.v4(), else: nil),
    splash: if(Faker.Util.pick([true, false, false, false, false]), do: Faker.UUID.v4(), else: nil),
    banner: if(Faker.Util.pick([true, false, false, false]), do: Faker.UUID.v4(), else: nil),
    description: if(Faker.Util.pick([true, true, false]), do: Faker.Lorem.sentence(5..20), else: nil),
    discovery_splash: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)), do: Faker.UUID.v4(), else: nil),

    owner_id: generate_snowflake(),
    region: Faker.Util.pick(["us-east", "us-west", "us-central", "eu-west", "eu-central", "singapore", "brazil"]),

    # Sometimes nil channel IDs
    afk_channel_id: if(Faker.Util.pick([true, false]), do: generate_snowflake(), else: nil),
    afk_timeout: Faker.Util.pick([60, 300, 900, 1800, 3600]),

    verification_level: Faker.random_between(0, 4),
    default_message_notifications: Faker.random_between(0, 1),
    explicit_content_filter: Faker.random_between(0, 2),

    # CRITICAL: Add roles map (Nostrum converts array to map)
    roles: generate_roles_map(3..10, guild_id),

    # CRITICAL: Add emojis array
    emojis: Enum.map(1..Faker.random_between(0, 5), fn _ ->
      Map.from_struct(emoji(%{guild_id: guild_id}))
    end),

    features: Faker.Util.pick([
      [],
      ["INVITE_SPLASH"],
      ["VANITY_URL", "INVITE_SPLASH"],
      ["COMMUNITY", "NEWS"],
      ["DISCOVERABLE", "COMMUNITY"]
    ]),

    mfa_level: Faker.random_between(0, 1),

    # Optional fields
    application_id: if(Faker.Util.pick([true, false, false, false]), do: generate_snowflake(), else: nil),
    widget_enabled: if(Faker.Util.pick([true, false, false]), do: true, else: nil),
    widget_channel_id: if(Faker.Util.pick([true, false, false]), do: generate_snowflake(), else: nil),
    system_channel_id: if(Faker.Util.pick([true, true, false]), do: generate_snowflake(), else: nil),
    system_channel_flags: Faker.random_between(0, 15),
    rules_channel_id: if(Faker.Util.pick([true, false, false]), do: generate_snowflake(), else: nil),

    # GUILD_CREATE specific fields
    joined_at: Faker.DateTime.backward(365) |> DateTime.to_iso8601(),
    large: Faker.Util.pick([true, false]),
    unavailable: if(Faker.Util.pick([true] ++ List.duplicate(false, 19)), do: true, else: nil),
    member_count: Faker.random_between(2, 50_000),

    # CRITICAL: Add voice_states array
    voice_states: Enum.map(1..Faker.random_between(0, 3), fn _ ->
      Map.from_struct(voice_state(%{guild_id: guild_id}))
    end),

    # CRITICAL: Add channels map (Nostrum converts array to map)
    channels: generate_channels_map(5..15, guild_id),

    # CRITICAL: Add threads map (Nostrum converts array to map)
    threads: generate_threads_map(0..5, guild_id),

    guild_scheduled_events: [],

    vanity_url_code: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)), do: Faker.Lorem.characters(4..8) |> to_string(), else: nil),

    # CRITICAL: Add stickers array
    stickers: Enum.map(1..Faker.random_between(0, 3), fn _ ->
      Map.from_struct(sticker(%{guild_id: guild_id}))
    end),

    public_updates_channel_id: if(Faker.Util.pick([true, false, false]), do: generate_snowflake(), else: nil),
    safety_alerts_channel_id: if(Faker.Util.pick([true, false, false]), do: generate_snowflake(), else: nil),

    max_presences: nil,  # Almost always null per Discord docs
    max_members: Faker.Util.pick([100_000, 250_000, 500_000]),

    premium_tier: Faker.random_between(0, 3),
    premium_subscription_count: if(Faker.Util.pick([true, true, false]), do: Faker.random_between(0, 50), else: nil),
    preferred_locale: Faker.Util.pick(["en-US", "en-GB", "de", "fr", "es-ES", "ja", "pt-BR"]),

    max_video_channel_users: if(Faker.Util.pick([true, false]), do: Faker.Util.pick([25, 50]), else: nil),
    max_stage_video_channel_users: if(Faker.Util.pick([true, false]), do: Faker.Util.pick([50, 150]), else: nil),

    welcome_screen: if(Faker.Util.pick([true, false, false]), do: %{
      description: Faker.Lorem.sentence(5..15),
      welcome_channels: []
    }, else: nil),

    nsfw_level: Faker.random_between(0, 3),
    premium_progress_bar_enabled: Faker.Util.pick([true, false])
  }

  struct(Nostrum.Struct.Guild, merge_attrs(defaults, attrs))
end

# Helper to generate roles map (Nostrum format)
defp generate_roles_map(count_range, guild_id) do
  count = Faker.random_between(elem(count_range, 0), elem(count_range, 1))

  Enum.reduce(1..count, %{}, fn _, acc ->
    role_struct = role(%{guild_id: guild_id})
    Map.put(acc, role_struct.id, role_struct)
  end)
end

# Helper to generate channels map (Nostrum format)
defp generate_channels_map(count_range, guild_id) do
  count = Faker.random_between(elem(count_range, 0), elem(count_range, 1))

  Enum.reduce(1..count, %{}, fn _, acc ->
    channel_struct = channel(%{guild_id: guild_id})
    Map.put(acc, channel_struct.id, channel_struct)
  end)
end

# Helper to generate threads map (Nostrum format)
defp generate_threads_map(count_range, guild_id) do
  count = Faker.random_between(elem(count_range, 0), elem(count_range, 1))

  Enum.reduce(1..count, %{}, fn _, acc ->
    thread_struct = thread(%{guild_id: guild_id})
    Map.put(acc, thread_struct.id, thread_struct)
  end)
end
```

## Testing Recommendations

### 1. Add Property-Based Tests for Nullable Fields

```elixir
test "guild generator produces nil for nullable fields" do
  # Run generator 100 times and verify nil values occur
  guilds = Enum.map(1..100, fn _ -> Discord.guild() end)

  # At least some guilds should have nil icon
  assert Enum.any?(guilds, fn g -> is_nil(g.icon) end),
         "Generator should sometimes produce nil icon"

  # At least some guilds should have nil description
  assert Enum.any?(guilds, fn g -> is_nil(g.description) end),
         "Generator should sometimes produce nil description"
end
```

### 2. Add Tests for Collection Presence

```elixir
test "guild generator produces required collections" do
  guild = Discord.guild()

  assert is_map(guild.roles), "roles should be a map"
  assert map_size(guild.roles) > 0, "roles should not be empty"

  assert is_map(guild.channels), "channels should be a map"
  assert map_size(guild.channels) > 0, "channels should not be empty"

  assert is_list(guild.emojis), "emojis should be a list"
  assert is_list(guild.voice_states), "voice_states should be a list"
end
```

### 3. Add Validation Against Payload Type

```elixir
test "generator produces valid Guild payload" do
  nostrum_guild = Discord.guild()

  # Should be able to convert to AshDiscord.Consumer.Payloads.Guild
  assert {:ok, _payload} = AshDiscord.Consumer.Payloads.Guild.new(nostrum_guild)
end
```

## Summary of Required Actions

### Immediate (P0)

1. ✅ Verify `threads` field is `:map` type (already done per verification
   report)
2. ❌ Add `allow_nil?: true` to 18 fields in payload (see Critical Issue #2)
3. ❌ Add roles, channels, emojis, voice_states, threads to generator (see
   Critical Issue #3)

### High Priority (P1)

4. ❌ Update generator to sometimes produce nil for nullable fields (see Medium
   Issue #4)
5. ❌ Add GUILD_CREATE specific fields to generator (see Medium Issue #5)

### Medium Priority (P2)

6. ❌ Add missing Discord API fields to payload (see Medium Issue #6)
7. ❌ Add helper functions for generating maps (roles, channels, threads)

### Low Priority (P3)

8. ❌ Update deprecated field description (see Low Issue #7)
9. ❌ Improve generator realism with varied distributions (see Low Issue #8)

## Alignment Summary

| Aspect                           | Payload             | Generator        | Alignment Status     |
| -------------------------------- | ------------------- | ---------------- | -------------------- |
| Core fields (id, name, owner_id) | ✅ Present          | ✅ Generated     | ✅ Aligned           |
| Nullable markers                 | ❌ Missing          | N/A              | ❌ Misaligned        |
| `threads` type                   | ✅ Correct (`:map`) | ❌ Not generated | ⚠️ Partially aligned |
| `roles` collection               | ✅ Defined          | ❌ Not generated | ❌ Misaligned        |
| `channels` collection            | ✅ Defined          | ❌ Not generated | ❌ Misaligned        |
| `emojis` collection              | ✅ Defined          | ❌ Not generated | ❌ Misaligned        |
| `voice_states` collection        | ✅ Defined          | ❌ Not generated | ❌ Misaligned        |
| GUILD_CREATE fields              | ✅ Defined          | ❌ Not generated | ❌ Misaligned        |
| Nullable field nil generation    | N/A                 | ❌ Never nil     | ❌ Incorrect         |
| Missing API fields               | ❌ 9 fields missing | N/A              | ⚠️ Incomplete        |

**Overall Alignment Score**: 3/10 (Significant work needed)

## Conclusion

The Guild payload structure is mostly correct with the `threads` type fix
already applied, but critical nullability markers are missing. The generator is
**significantly incomplete** and requires substantial work to:

1. Generate required collections (roles, channels, emojis, voice_states,
   threads, stickers)
2. Properly handle nullable fields by sometimes generating nil
3. Include GUILD_CREATE-specific fields
4. Match real-world data distributions

**Priority**: Address Critical Issues #2 and #3 immediately to enable proper
testing of Guild-related functionality.

## References

- Discord API Guild Object:
  https://discord.com/developers/docs/resources/guild#guild-object
- Nostrum Guild Struct: https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.html
- Verification Report:
  `/home/joba/sandbox/ash_discord/verification_reports/guild_verification.md`
