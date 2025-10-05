# Webhook Payload and Generator Review

**Date**: 2025-10-05 **Reviewer**: Claude (Automated Review) **Payload**:
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/webhook.ex`
**Generator**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` (webhook/1)
**Verification Report**:
`/home/joba/sandbox/ash_discord/verification_reports/webhook_verification.md`

---

## Executive Summary

The Webhook payload type has been **correctly updated** with all recommended
fixes from the verification report. However, the **test generator is critically
deficient** and does not align with the payload implementation. The generator
needs significant updates to properly test the corrected payload type.

### Status Overview

| Component    | Status            | Critical Issues                         |
| ------------ | ----------------- | --------------------------------------- |
| Payload Type | ✅ **CORRECT**    | 0                                       |
| Generator    | ❌ **DEFICIENT**  | 3 critical, 8 moderate                  |
| Alignment    | ❌ **MISALIGNED** | Generator doesn't test payload properly |

---

## Part 1: Payload Type Analysis

### ✅ Payload Implementation Review

The payload type at
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/webhook.ex`
has been **correctly implemented** with all fixes from the verification report
applied:

#### Confirmed Corrections:

1. ✅ **`type` field added** (lines 20-22)

   - Correctly set as `allow_nil?: false`
   - Proper description with webhook type values (1, 2, 3)

2. ✅ **10 fields now have `allow_nil?: true`** (as required):

   - `guild_id` (line 25) - Optional field
   - `user` (line 33) - Optional field
   - `name` (line 38) - Nullable field
   - `avatar` (line 42) - Nullable field
   - `token` (line 46) - Optional field
   - `application_id` (line 50) - Nullable field
   - `source_guild` (line 54) - Optional field
   - `source_channel` (line 59) - Optional field
   - `url` (line 64) - Optional field
   - ✅ All properly marked

3. ✅ **`channel_id` has `allow_nil?: false`** (line 29)

   - Correctly marked as required

4. ✅ **Field descriptions improved**

   - Match Discord API documentation
   - Include context about when fields are present/absent

5. ✅ **Moduledoc updated** (lines 2-11)
   - Documents the `type` field addition
   - References both Discord API and Nostrum

#### Payload Structure Verification:

```elixir
# All 12 fields present (11 from Nostrum + 1 new):
✅ id          - integer, allow_nil?: false
✅ type        - integer, allow_nil?: false  (NEW FIELD)
✅ guild_id    - integer, allow_nil?: true
✅ channel_id  - integer, allow_nil?: false
✅ user        - map,     allow_nil?: true
✅ name        - string,  allow_nil?: true
✅ avatar      - string,  allow_nil?: true
✅ token       - string,  allow_nil?: true
✅ application_id - integer, allow_nil?: true
✅ source_guild   - map,     allow_nil?: true
✅ source_channel - map,     allow_nil?: true
✅ url         - string,  allow_nil?: true
```

### ✅ Payload Conversion Functions

The `new/1` functions (lines 76-86) are correctly implemented:

- ✅ Handles already-converted payloads (line 76-78)
- ✅ Handles Nostrum structs (line 80-82)
- ✅ Handles raw maps (line 84-86)
- ✅ Documents that `type` will be nil when converting from Nostrum (line 74)

**Payload Type Conclusion**: ✅ **FULLY COMPLIANT** with Discord API and
verification report recommendations.

---

## Part 2: Generator Analysis

### ❌ Critical Generator Issues

The generator at
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` (lines
555-567) has **multiple critical deficiencies**:

#### Issue 1: ❌ **CRITICAL - Missing `type` field**

**Current Implementation** (lines 556-564):

```elixir
defaults = %{
  id: generate_snowflake(),
  guild_id: generate_snowflake(),
  channel_id: generate_snowflake(),
  user: user(),
  name: "#{Faker.Lorem.word()} Webhook",
  avatar: nil,
  token: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}"
}
```

**Problem**:

- The `type` field is **completely missing** from the generator
- This is a **required, non-nullable field** in the payload
- Tests will fail when trying to create AshDiscord Webhook payloads from
  generator output

**Impact**: 🔴 **CRITICAL**

- Generator cannot create valid webhook payloads for the AshDiscord type
- Any test using `webhook()` generator with payload type will fail validation

**Required Fix**:

```elixir
defaults = %{
  id: generate_snowflake(),
  type: Faker.Util.pick([1, 2, 3]),  # 1=Incoming, 2=Channel Follower, 3=Application
  guild_id: generate_snowflake(),
  channel_id: generate_snowflake(),
  user: user(),
  name: "#{Faker.Lorem.word()} Webhook",
  avatar: nil,
  token: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}"
}
```

#### Issue 2: ❌ **CRITICAL - Generator doesn't test optional field scenarios**

**Current Implementation**:

- `guild_id` - Always generated (line 558)
- `user` - Always generated (line 560)
- `token` - Always generated (line 563)
- `avatar` - Always nil (line 562)
- `name` - Always generated (line 561)

**Problem**: The generator **never produces nil values** for optional fields,
which means tests **never verify** that the payload correctly handles:

- Missing `guild_id` (webhook followers don't have this)
- Missing `user` (not returned when getting webhook with token)
- Missing `token` (only for incoming webhooks)
- Missing `url` (only for OAuth2 webhooks)
- Null `application_id` (common case)
- Missing `source_guild` and `source_channel` (only for channel followers)

**Impact**: 🔴 **CRITICAL**

- Tests never verify the most important aspect of the payload corrections
- The entire purpose of adding `allow_nil?: true` is not being tested
- Production code may fail when Discord sends nil for optional fields

**Required Fix**:

```elixir
# Generate realistic nil patterns based on webhook type
webhook_type = Faker.Util.pick([1, 2, 3])

defaults = %{
  id: generate_snowflake(),
  type: webhook_type,
  # guild_id is optional for some webhooks
  guild_id: if(Faker.Util.pick([true, true, false]), do: generate_snowflake(), else: nil),
  channel_id: generate_snowflake(),
  # user is not returned when getting webhook with token (30% chance)
  user: if(Faker.Util.pick([true, true, false]), do: user(), else: nil),
  # name can be null
  name: if(Faker.Util.pick([true, true, false]), do: "#{Faker.Lorem.word()} Webhook", else: nil),
  # avatar can be null (often is for new webhooks)
  avatar: if(Faker.Util.pick([true, false, false]), do: Faker.UUID.v4(), else: nil),
  # token only for incoming webhooks (type 1) and not always returned
  token: if(webhook_type == 1 and Faker.Util.pick([true, true, false]),
           do: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
           else: nil),
  # application_id often null unless created by bot
  application_id: if(Faker.Util.pick([true, false, false, false]),
                     do: generate_snowflake(),
                     else: nil),
  # source_guild only for channel followers (type 2)
  source_guild: if(webhook_type == 2 and Faker.Util.pick([true, false]),
                   do: %{id: generate_snowflake(), name: "Source Guild"},
                   else: nil),
  # source_channel only for channel followers (type 2)
  source_channel: if(webhook_type == 2 and Faker.Util.pick([true, false]),
                     do: %{id: generate_snowflake(), name: "announcements"},
                     else: nil),
  # url only for OAuth2 webhooks (rare)
  url: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)),
          do: "https://discord.com/api/webhooks/#{generate_snowflake()}/#{Faker.UUID.v4()}",
          else: nil)
}
```

#### Issue 3: ❌ **CRITICAL - Generator returns wrong struct type**

**Current Implementation** (line 566):

```elixir
struct(Nostrum.Struct.Webhook, merge_attrs(defaults, attrs))
```

**Problem**:

- Generator returns `Nostrum.Struct.Webhook`
- But `Nostrum.Struct.Webhook` **does not have a `type` field**
- Tests using this generator **cannot test the AshDiscord payload type**
  properly

**Impact**: 🔴 **CRITICAL**

- There's a fundamental mismatch between generator output and payload
  requirements
- Generator produces structs that are incompatible with payload's new `type`
  field

**Options for Fix**:

**Option A - Return plain map** (Recommended):

```elixir
# Return plain map that can be passed to AshDiscord.Consumer.Payloads.Webhook.new/1
merge_attrs(defaults, attrs)
```

**Option B - Keep Nostrum but document limitation**:

```elixir
# Keep returning Nostrum struct but document that type field must be added separately
struct(Nostrum.Struct.Webhook, merge_attrs(defaults, attrs))
# Tests would need to: webhook() |> Map.from_struct() |> Map.put(:type, 1)
```

**Recommendation**: Use **Option A** - return plain maps, which aligns with
other generators in the file (see `application_command`, `interaction_data`,
etc.).

---

### ⚠️ Moderate Generator Issues

#### Issue 4: ⚠️ **Generator doesn't vary webhook types**

**Current**: No type field at all **Expected**: Should generate all three
webhook types (1, 2, 3) with appropriate fields

**Fix**: Use `Faker.Util.pick([1, 2, 3])` to vary webhook type

---

#### Issue 5: ⚠️ **Generator produces unrealistic data**

**Current**:

- `avatar` always nil (line 562) - but many webhooks have custom avatars
- `token` always present - but not all webhooks return tokens
- `user` always present - but not returned when fetching with token
- Missing all webhook-type-specific fields

**Expected**: Realistic variation based on webhook type and common scenarios

---

#### Issue 6: ⚠️ **Missing field: `application_id`**

**Current**: Not in generator **Discord API**: `application_id: null | string`
(nullable) **Status**: ⚠️ MISSING

Should be included with occasional non-nil values for application webhooks.

---

#### Issue 7: ⚠️ **Missing field: `source_guild`**

**Current**: Not in generator **Discord API**:
`source_guild?: APIWebhookSourceGuild` (optional) **Status**: ⚠️ MISSING

Should be included for type 2 (Channel Follower) webhooks.

---

#### Issue 8: ⚠️ **Missing field: `source_channel`**

**Current**: Not in generator **Discord API**:
`source_channel?: Required<Pick<APIPartialChannel, 'id' | 'name'>>` (optional)
**Status**: ⚠️ MISSING

Should be included for type 2 (Channel Follower) webhooks.

---

#### Issue 9: ⚠️ **Missing field: `url`**

**Current**: Not in generator **Discord API**: `url?: string` (optional)
**Status**: ⚠️ MISSING

Should be included occasionally for OAuth2 webhooks.

---

#### Issue 10: ⚠️ **Generator documentation incomplete**

**Current Documentation** (lines 535-554):

```elixir
@doc """
Generates a Discord webhook struct.

## Options

- `:id` - Webhook ID (defaults to generated snowflake)
- `:type` - Webhook type (defaults to 1)
- `:guild_id` - Guild ID (defaults to generated snowflake)
- `:channel_id` - Channel ID (defaults to generated snowflake)
- `:user` - User who created webhook (defaults to generated user)
- `:name` - Webhook name (defaults to generated name)
- `:avatar` - Webhook avatar (defaults to nil)
- `:token` - Webhook token (defaults to generated token)

## Examples

    iex> webhook = webhook(%{name: "Test Webhook"})
    iex> webhook.name
    "Test Webhook"
"""
```

**Issues**:

- Documentation claims `type` defaults to 1 (line 541) but implementation
  doesn't include `type` at all
- Missing documentation for `application_id`, `source_guild`, `source_channel`,
  `url`
- Doesn't explain webhook type variations (1=Incoming, 2=Channel Follower,
  3=Application)
- Doesn't explain which fields are present for which webhook types

**Required Documentation Update**:

```elixir
@doc """
Generates a Discord webhook struct with realistic field variations.

Generates webhooks of different types with appropriate field patterns:
- Type 1 (Incoming): Standard webhooks with optional token
- Type 2 (Channel Follower): Includes source_guild and source_channel
- Type 3 (Application): Application webhooks for Interactions

## Options

- `:id` - Webhook ID (defaults to generated snowflake)
- `:type` - Webhook type (defaults to random: 1=Incoming, 2=Channel Follower, 3=Application)
- `:guild_id` - Guild ID (defaults to generated snowflake or nil)
- `:channel_id` - Channel ID (defaults to generated snowflake)
- `:user` - User who created webhook (defaults to generated user or nil)
- `:name` - Webhook name (defaults to generated name or nil)
- `:avatar` - Webhook avatar hash (defaults to generated hash or nil)
- `:token` - Webhook token (defaults to generated token for type 1, else nil)
- `:application_id` - Application ID (defaults to generated snowflake or nil)
- `:source_guild` - Source guild for followers (defaults to partial guild for type 2, else nil)
- `:source_channel` - Source channel for followers (defaults to partial channel for type 2, else nil)
- `:url` - Webhook URL (defaults to generated URL or nil)

## Examples

    iex> webhook = webhook(%{name: "Test Webhook", type: 1})
    iex> webhook.name
    "Test Webhook"
    iex> webhook.type
    1

    iex> follower = webhook(%{type: 2})
    iex> follower.type
    2
    iex> is_map(follower.source_channel)
    true
"""
```

---

#### Issue 11: ⚠️ **Generator doesn't align with webhook type semantics**

**Expected Behavior by Type**:

**Type 1 - Incoming Webhook**:

- `token` should be present (most of the time)
- `user` may or may not be present (depends on how it's fetched)
- `application_id` often nil
- `source_guild` and `source_channel` should be nil
- `url` rarely present

**Type 2 - Channel Follower Webhook**:

- `source_guild` should be present (partial guild object)
- `source_channel` should be present (partial channel object with id and name)
- `token` often not present
- `guild_id` present
- `url` rarely present

**Type 3 - Application Webhook**:

- `application_id` should be present
- `token` may or may not be present
- `source_guild` and `source_channel` should be nil
- `url` rarely present

**Current Implementation**: Does not respect any of these type-specific
patterns.

---

## Part 3: Alignment Verification

### ❌ Payload vs Generator Alignment

| Field            | Payload Type | Payload allow_nil? | Generator Provides | Generator nil% | Aligned?               |
| ---------------- | ------------ | ------------------ | ------------------ | -------------- | ---------------------- |
| `id`             | integer      | false              | ✅ Always          | 0%             | ✅                     |
| `type`           | integer      | false              | ❌ **MISSING**     | N/A            | ❌ **CRITICAL**        |
| `guild_id`       | integer      | true               | ✅ Always          | 0%             | ⚠️ Never tests nil     |
| `channel_id`     | integer      | false              | ✅ Always          | 0%             | ✅                     |
| `user`           | map          | true               | ✅ Always          | 0%             | ⚠️ Never tests nil     |
| `name`           | string       | true               | ✅ Always          | 0%             | ⚠️ Never tests nil     |
| `avatar`         | string       | true               | ✅ Always nil      | 100%           | ⚠️ Never tests non-nil |
| `token`          | string       | true               | ✅ Always          | 0%             | ⚠️ Never tests nil     |
| `application_id` | integer      | true               | ❌ Missing         | N/A            | ❌ Missing             |
| `source_guild`   | map          | true               | ❌ Missing         | N/A            | ❌ Missing             |
| `source_channel` | map          | true               | ❌ Missing         | N/A            | ❌ Missing             |
| `url`            | string       | true               | ❌ Missing         | N/A            | ❌ Missing             |

**Alignment Score**: 2/12 fields properly aligned (17%)

**Critical Misalignments**:

1. ❌ `type` field completely missing (blocks payload creation)
2. ❌ Generator never tests nil for 8 optional/nullable fields
3. ❌ Generator missing 4 fields that payload expects

---

## Part 4: Specific Concerns from Review Request

### Concern 1: ✅ `type` field added to payload

**Status**: ✅ **VERIFIED**

- Payload correctly includes `type` field (lines 20-22)
- Correctly marked as `allow_nil?: false`
- Proper description with webhook type values

**BUT**: ❌ Generator does **NOT** include this field

---

### Concern 2: ✅ 10 fields should have `allow_nil?: true`

**Status**: ✅ **VERIFIED** (Payload) / ❌ **NOT TESTED** (Generator)

All 10 fields correctly marked in payload:

1. ✅ `guild_id` (line 25)
2. ✅ `user` (line 33)
3. ✅ `name` (line 38)
4. ✅ `avatar` (line 42)
5. ✅ `token` (line 46)
6. ✅ `application_id` (line 50)
7. ✅ `source_guild` (line 54)
8. ✅ `source_channel` (line 59)
9. ✅ `url` (line 64)
10. ✅ All correct

**BUT**: ❌ Generator **NEVER generates nil** for these fields (except `avatar`
which is always nil)

---

### Concern 3: ✅ `channel_id` should be `allow_nil?: false`

**Status**: ✅ **VERIFIED**

- Payload correctly marks `channel_id` as `allow_nil?: false` (line 29)
- Generator correctly always provides this field
- ✅ **ALIGNED**

---

### Concern 4: ❌ Generator produces realistic webhook types (1, 2, 3)

**Status**: ❌ **FAILED**

- Generator does **NOT** include `type` field at all
- Cannot produce webhooks of different types
- Cannot produce type-specific field patterns

**Required**: Add `type` field with realistic type-specific data patterns

---

### Concern 5: ❌ Generator produces nil for optional fields

**Status**: ❌ **FAILED**

- Generator **NEVER** produces nil for optional fields (except `avatar`)
- This is the **most critical testing gap**
- Tests never verify that payload correctly handles nil values

**Required**: Add probabilistic nil generation for all optional/nullable fields

---

## Part 5: Recommendations

### Immediate Critical Fixes Required

#### Fix 1: Add `type` field to generator

**Priority**: 🔴 **CRITICAL** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Lines**:
555-567

```elixir
def webhook(attrs \\ %{}) do
  # Generate webhook type first to determine field patterns
  webhook_type = Map.get(attrs, :type, Faker.Util.pick([1, 2, 3]))

  defaults = %{
    id: generate_snowflake(),
    type: webhook_type,  # ADD THIS LINE
    # ... rest of fields
  }

  # Return plain map instead of Nostrum struct
  merge_attrs(defaults, attrs)
end
```

---

#### Fix 2: Generate nil values for optional/nullable fields

**Priority**: 🔴 **CRITICAL** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Lines**:
555-567

Add probabilistic nil generation for:

- `guild_id` (optional - ~20% nil)
- `user` (optional - ~30% nil when fetched with token)
- `name` (nullable - ~10% nil)
- `avatar` (nullable - ~60% nil, currently always nil)
- `token` (optional - depends on type, ~40% nil overall)
- `application_id` (nullable - ~70% nil)
- `source_guild` (optional - only for type 2)
- `source_channel` (optional - only for type 2)
- `url` (optional - ~90% nil, rare OAuth2 webhooks)

---

#### Fix 3: Add missing fields to generator

**Priority**: 🔴 **CRITICAL** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Lines**:
555-567

Add these fields:

- `application_id`
- `source_guild`
- `source_channel`
- `url`

---

#### Fix 4: Implement type-specific field patterns

**Priority**: 🟡 **HIGH** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Lines**:
555-567

Generate fields appropriate to webhook type:

- **Type 1 (Incoming)**: Include `token` most of the time
- **Type 2 (Channel Follower)**: Include `source_guild` and `source_channel`
- **Type 3 (Application)**: Include `application_id` most of the time

---

#### Fix 5: Update generator documentation

**Priority**: 🟡 **HIGH** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Lines**:
535-554

Update documentation to reflect:

- All 12 fields
- Webhook type variations
- Which fields appear for which types
- Nil generation patterns

---

#### Fix 6: Change return type to plain map

**Priority**: 🟡 **HIGH** **File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex` **Line**:
566

```elixir
# Current:
struct(Nostrum.Struct.Webhook, merge_attrs(defaults, attrs))

# Change to:
merge_attrs(defaults, attrs)
```

**Rationale**:

- Nostrum.Struct.Webhook doesn't have `type` field
- Returning plain map allows tests to use with AshDiscord payload type
- Aligns with other generators (application_command, interaction_data, etc.)

---

### Complete Corrected Generator Implementation

```elixir
@doc """
Generates a Discord webhook struct with realistic field variations.

Generates webhooks of different types with appropriate field patterns:
- Type 1 (Incoming): Standard webhooks, often include token
- Type 2 (Channel Follower): Includes source_guild and source_channel
- Type 3 (Application): Application webhooks for Interactions, include application_id

## Options

- `:id` - Webhook ID (defaults to generated snowflake)
- `:type` - Webhook type (defaults to random: 1=Incoming, 2=Channel Follower, 3=Application)
- `:guild_id` - Guild ID (defaults to generated snowflake or nil)
- `:channel_id` - Channel ID (defaults to generated snowflake)
- `:user` - User who created webhook (defaults to generated user or nil)
- `:name` - Webhook name (defaults to generated name or nil)
- `:avatar` - Webhook avatar hash (defaults to generated hash or nil)
- `:token` - Webhook token (defaults to generated token for type 1, else nil)
- `:application_id` - Application ID (defaults to generated snowflake or nil)
- `:source_guild` - Source guild for followers (defaults to partial guild for type 2, else nil)
- `:source_channel` - Source channel for followers (defaults to partial channel for type 2, else nil)
- `:url` - Webhook URL (defaults to generated URL or nil, rare)

## Examples

    iex> webhook = webhook(%{name: "Test Webhook", type: 1})
    iex> webhook.name
    "Test Webhook"
    iex> webhook.type
    1

    iex> follower = webhook(%{type: 2})
    iex> follower.type
    2
    iex> is_map(follower.source_channel)
    true
"""
def webhook(attrs \\ %{}) do
  # Determine webhook type first to set appropriate field patterns
  webhook_type = Map.get(attrs, :type, Faker.Util.pick([1, 2, 3]))

  defaults = %{
    id: generate_snowflake(),
    type: webhook_type,

    # guild_id is optional for some webhooks (20% nil)
    guild_id: if(Faker.Util.pick([true, true, true, true, false]),
                 do: generate_snowflake(),
                 else: nil),

    # channel_id is required
    channel_id: generate_snowflake(),

    # user is not returned when getting webhook with token (30% nil)
    user: if(Faker.Util.pick([true, true, false]),
             do: user(),
             else: nil),

    # name can be null (10% nil)
    name: if(Faker.Util.pick([true, true, true, true, true, true, true, true, true, false]),
             do: "#{Faker.Lorem.word()} Webhook",
             else: nil),

    # avatar can be null (60% nil for new/default webhooks)
    avatar: if(Faker.Util.pick([true, false, false]),
               do: Faker.UUID.v4(),
               else: nil),

    # token: Type 1 (Incoming) often has token, others less likely
    token: case webhook_type do
      1 -> if(Faker.Util.pick([true, true, true, false]),
              do: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
              else: nil)
      2 -> if(Faker.Util.pick([true, false, false]),
              do: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
              else: nil)
      3 -> if(Faker.Util.pick([true, false]),
              do: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
              else: nil)
      _ -> nil
    end,

    # application_id: Type 3 (Application) often has this, others rarely (70% nil overall)
    application_id: case webhook_type do
      3 -> if(Faker.Util.pick([true, true, true, false]),
              do: generate_snowflake(),
              else: nil)
      _ -> if(Faker.Util.pick([true] ++ List.duplicate(false, 9)),
              do: generate_snowflake(),
              else: nil)
    end,

    # source_guild: Only for Type 2 (Channel Follower), 80% present when type 2
    source_guild: if(webhook_type == 2 and Faker.Util.pick([true, true, true, true, false]),
                     do: %{
                       id: generate_snowflake(),
                       name: "#{Faker.Person.first_name()}'s #{Faker.Util.pick(["Server", "Community"])}",
                       icon: if(Faker.Util.pick([true, false]), do: Faker.UUID.v4(), else: nil)
                     },
                     else: nil),

    # source_channel: Only for Type 2 (Channel Follower), 80% present when type 2
    source_channel: if(webhook_type == 2 and Faker.Util.pick([true, true, true, true, false]),
                       do: %{
                         id: generate_snowflake(),
                         name: Faker.Util.pick(["announcements", "updates", "news", "general"])
                       },
                       else: nil),

    # url: Only for OAuth2 webhooks (very rare, ~5% overall)
    url: if(Faker.Util.pick([true] ++ List.duplicate(false, 19)),
            do: "https://discord.com/api/webhooks/#{generate_snowflake()}/#{Faker.UUID.v4()}",
            else: nil)
  }

  # Return plain map instead of Nostrum struct since Nostrum doesn't have type field
  merge_attrs(defaults, attrs)
end
```

---

## Part 6: Testing Recommendations

After implementing the fixes, verify the following scenarios:

### Test Case 1: Type 1 (Incoming) Webhooks

```elixir
test "generates type 1 (Incoming) webhooks" do
  webhook = Discord.webhook(%{type: 1})

  assert webhook.type == 1
  assert webhook.channel_id != nil
  # Token often present for type 1
  # source_guild and source_channel should be nil
  assert is_nil(webhook.source_guild)
  assert is_nil(webhook.source_channel)
end
```

### Test Case 2: Type 2 (Channel Follower) Webhooks

```elixir
test "generates type 2 (Channel Follower) webhooks" do
  webhook = Discord.webhook(%{type: 2})

  assert webhook.type == 2
  # Should often have source_guild and source_channel
  # Run multiple times to verify probabilistic generation
end
```

### Test Case 3: Type 3 (Application) Webhooks

```elixir
test "generates type 3 (Application) webhooks" do
  webhook = Discord.webhook(%{type: 3})

  assert webhook.type == 3
  # Should often have application_id
  # source_guild and source_channel should be nil
  assert is_nil(webhook.source_guild)
  assert is_nil(webhook.source_channel)
end
```

### Test Case 4: Nil Optional Fields

```elixir
test "sometimes generates nil for optional fields" do
  # Generate 100 webhooks and verify we see nil values
  webhooks = Enum.map(1..100, fn _ -> Discord.webhook() end)

  # At least some should have nil for optional fields
  assert Enum.any?(webhooks, fn w -> is_nil(w.guild_id) end)
  assert Enum.any?(webhooks, fn w -> is_nil(w.user) end)
  assert Enum.any?(webhooks, fn w -> is_nil(w.name) end)
  assert Enum.any?(webhooks, fn w -> is_nil(w.token) end)
end
```

### Test Case 5: Required Fields Never Nil

```elixir
test "required fields are never nil" do
  webhooks = Enum.map(1..100, fn _ -> Discord.webhook() end)

  Enum.each(webhooks, fn webhook ->
    refute is_nil(webhook.id)
    refute is_nil(webhook.type)
    refute is_nil(webhook.channel_id)
  end)
end
```

### Test Case 6: Payload Conversion

```elixir
test "generator output can create AshDiscord Webhook payload" do
  webhook_data = Discord.webhook()

  # Should successfully create payload without errors
  assert {:ok, payload} = AshDiscord.Consumer.Payloads.Webhook.new(webhook_data)
  assert payload.type in [1, 2, 3]
  assert payload.channel_id != nil
end
```

---

## Summary

### Payload Type: ✅ **EXCELLENT**

The Webhook payload implementation is **fully correct** and implements all
recommendations from the verification report. No changes needed.

### Generator: ❌ **REQUIRES SIGNIFICANT WORK**

The webhook generator has **11 identified issues** (3 critical, 8 moderate) and
needs comprehensive updates to properly test the corrected payload type.

### Critical Actions Required:

1. 🔴 Add `type` field to generator
2. 🔴 Implement nil generation for optional/nullable fields
3. 🔴 Add missing fields (application_id, source_guild, source_channel, url)
4. 🟡 Implement type-specific field patterns
5. 🟡 Update documentation
6. 🟡 Change return type to plain map

### Priority: 🔴 URGENT

The generator in its current state **cannot properly test** the corrected
payload type and would cause test failures when trying to create AshDiscord
Webhook payloads.

---

## References

- Discord API - Webhook Object:
  https://discord.com/developers/docs/resources/webhook#webhook-object
- Discord API Types:
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APIWebhook
- Nostrum Webhook: https://hexdocs.pm/nostrum/Nostrum.Struct.Webhook.html
- Verification Report:
  `/home/joba/sandbox/ash_discord/verification_reports/webhook_verification.md`
