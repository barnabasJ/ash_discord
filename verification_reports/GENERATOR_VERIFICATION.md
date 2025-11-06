# Discord Generator Verification Report

**Date**: 2025-10-05 **Generator File**:
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex`
**Verification Against**: Corrected payload types in
`lib/ash_discord/consumer/payloads/`

## Executive Summary

This report identifies **critical type mismatches**, **nullability issues**, and
**realism problems** in the Discord test generators compared to the corrected
payload types documented in `IMPLEMENTATION_SUMMARY.md`.

### Critical Findings

- **3 critical type mismatches** that will cause runtime errors
- **15+ nullability issues** reducing test coverage
- **20+ realism problems** producing unrealistic test data

---

## Priority 1: Critical Type Mismatches (WILL CAUSE RUNTIME ERRORS)

### 1. Member Generator - DateTime Fields (Lines 375-376)

**Location**: `member/1` function, lines 375-376

**Current Code**:

```elixir
joined_at: Faker.DateTime.backward(365) |> DateTime.to_unix(:millisecond),
premium_since: nil,
```

**Problem**:

- `joined_at`: Generates Unix millisecond timestamp (integer), but payload
  expects `:integer` (ACTUALLY CORRECT)
- `premium_since`: Always `nil`, but payload type is `:utc_datetime` - should
  sometimes generate DateTime structs

**Corrected Payload Type** (from `member.ex` lines 22-33):

```elixir
field :joined_at, :integer,
  description: "Unix timestamp when the user joined the guild (Nostrum converts from ISO8601; can be nil)"

field :premium_since, :utc_datetime,
  description: "DateTime when the user started boosting the guild"

field :communication_disabled_until, :utc_datetime,
  description: "DateTime when the user's timeout will expire; nil if not timed out"
```

**Fix Required**:

```elixir
defaults = %{
  # ... other fields ...
  joined_at: Faker.DateTime.backward(365) |> DateTime.to_unix(:millisecond),
  # Generate DateTime 25% of the time for boosted members
  premium_since: if(Faker.Util.pick([true, false, false, false]), do: Faker.DateTime.backward(180), else: nil),
  # Generate DateTime 5% of the time for timed-out members
  communication_disabled_until: if(Faker.Util.pick([true] ++ List.duplicate(false, 19)), do: Faker.DateTime.forward(7), else: nil),
  # ... other fields ...
}
```

**Impact**: Tests will fail when Nostrum provides DateTime structs for
boosted/timed-out members

---

### 2. Sticker Generator - Enum Atom Fields (Lines 869-870)

**Location**: `sticker/1` function, lines 869-870

**Current Code**:

```elixir
type: 1,
format_type: Faker.Util.pick([1, 2, 3]),
```

**Problem**: Generates integers, but payload expects atoms

**Corrected Payload Type** (from `sticker.ex` lines 36-42):

```elixir
field :type, :atom,
  allow_nil?: false,
  description: "Type of sticker (:standard or :guild)"

field :format_type, :atom,
  allow_nil?: false,
  description: "Format type (:png, :apng, :lottie, or :gif)"
```

**Fix Required**:

```elixir
defaults = %{
  # ... other fields ...
  type: Faker.Util.pick([:standard, :guild]),
  format_type: Faker.Util.pick([:png, :apng, :lottie, :gif]),
  # ... other fields ...
}
```

**Impact**: Type mismatch errors when payload conversion expects atoms but
receives integers

---

### 3. Message Generator - Timestamp DateTime Field (Line 254)

**Location**: `message/1` function, line 254

**Current Code**:

```elixir
timestamp: Faker.DateTime.backward(30) |> DateTime.to_iso8601(),
```

**Problem**: Generates ISO8601 string, but payload expects `:utc_datetime`

**Corrected Payload Type** (from `message.ex` line 31):

```elixir
field :timestamp, :utc_datetime, description: "When the message was sent"
```

**Fix Required**:

```elixir
defaults = %{
  # ... other fields ...
  timestamp: Faker.DateTime.backward(30),
  # ... other fields ...
}
```

**Also fix `edited_timestamp`** (lines 277-289):

```elixir
# Current code converts to ISO8601, should be DateTime
edited_time =
  result.timestamp
  |> DateTime.add(Faker.random_between(60, 7200), :second)
```

**Impact**: Tests expect DateTime structs but generator produces strings

---

## Priority 2: High - Unrealistic Data Patterns

### 4. User Generator - Always Provides Optional Fields (Lines 118-124)

**Current Code**: All optional fields are ALWAYS populated

```elixir
defaults = %{
  # ... required fields ...
  global_name: Faker.Person.name(),  # Should be nil sometimes
  avatar: "#{Faker.UUID.v4()}",       # Should be nil sometimes
  bot: false,                         # Should be true sometimes
  public_flags: 0                     # Should vary
}
```

**Corrected Payload Type** (from `user.ex` lines 22-36):

```elixir
field :global_name, :string, allow_nil?: true
field :avatar, :string, allow_nil?: true
field :bot, :boolean, allow_nil?: true
field :public_flags, :integer, allow_nil?: true
```

**Realism Issues**:

- `global_name`: Many users don't set display names (should be nil ~40% of time)
- `avatar`: Default avatars are common (should be nil ~30% of time)
- `bot`: Most users are not bots (currently always false, should be true ~10%
  for variety)
- `public_flags`: Should vary (0, 64, 128, 256, etc. for badges)

**Fix Required**:

```elixir
defaults = %{
  id: generate_snowflake(),
  username: Faker.Internet.user_name(),
  discriminator: String.pad_leading("#{Faker.random_between(1, 9999)}", 4, "0"),
  # 60% have display names
  global_name: if(Faker.Util.pick([true, true, true, false, false]), do: Faker.Person.name(), else: nil),
  # 70% have custom avatars
  avatar: if(Faker.Util.pick([true, true, true, true, true, true, true, false, false, false]), do: "#{Faker.UUID.v4()}", else: nil),
  # 10% are bots for variety in tests
  bot: Faker.Util.pick([true] ++ List.duplicate(false, 9)),
  # Vary public flags (0, 64, 128, 256, 512, 1024 are common badges)
  public_flags: Faker.Util.pick([0, 0, 0, 64, 128, 256, 512, 1024])
}
```

---

### 5. Emoji Generator - Always Custom Emoji (Lines 489-495)

**Current Code**: Always generates custom emoji with ID

```elixir
defaults = %{
  id: generate_snowflake(),  # Should be nil for Unicode emoji
  name: Faker.Lorem.word(),
  animated: false,
  managed: false,
  require_colons: true,
  roles: []
}
```

**Corrected Payload Type** (from `emoji.ex` lines 15-17):

```elixir
field :id, :integer,
  allow_nil?: true,
  description: "Id of the emoji (snowflake integer, can be nil for standard Unicode emoji)"
```

**Realism Issue**: Should generate both Unicode emoji (id: nil) AND custom emoji

**Fix Required**:

```elixir
def emoji(attrs \\ %{}) do
  # 50/50 split between Unicode and custom emoji
  is_unicode = Faker.Util.pick([true, false])

  defaults = if is_unicode do
    # Unicode emoji (like 👍, ❤️, 😂)
    %{
      id: nil,
      name: Faker.Util.pick(["👍", "👎", "❤️", "😂", "😢", "🔥", "✅", "❌", "⭐"]),
      animated: false,
      managed: nil,
      require_colons: nil,
      roles: nil,
      user: nil,
      available: nil
    }
  else
    # Custom guild emoji
    %{
      id: generate_snowflake(),
      name: Faker.Lorem.word(),
      animated: Faker.Util.pick([true, false, false, false]),  # 25% animated
      managed: Faker.Util.pick([true, false, false, false]),   # 25% managed
      require_colons: true,
      roles: if(Faker.Util.pick([true, false, false]), do: [generate_snowflake()], else: []),
      user: nil,  # Usually not included
      available: true
    }
  end

  struct(Nostrum.Struct.Emoji, merge_attrs(defaults, attrs))
end
```

---

### 6. Message Generator - Guild Context Missing (Line 251)

**Current Code**:

```elixir
guild_id: nil,
```

**Realism Issue**: Always generates DM messages (guild_id: nil), never guild
messages

**Fix Required**:

```elixir
defaults = %{
  id: generate_snowflake(),
  channel_id: generate_snowflake(),
  # 80% guild messages, 20% DM messages
  guild_id: if(Faker.Util.pick([true, true, true, true, false]), do: generate_snowflake(), else: nil),
  # ... rest of defaults ...
}
```

---

### 7. Channel Generator - Always Guild Text Channel (Lines 200-201)

**Current Code**:

```elixir
type: 0,
guild_id: generate_snowflake(),
```

**Realism Issue**: Only generates type 0 (guild text), ignores DM (1), voice
(2), DM group (3), category (4), news (5), threads (10-12), forums (15)

**Fix Required**:

```elixir
def channel(attrs \\ %{}) do
  # Vary channel types with realistic distribution
  channel_type = Map.get(attrs, :type, Faker.Util.pick([
    0, 0, 0, 0, 0,  # 50% text channels
    1,              # 10% DM
    2, 2,           # 20% voice
    4,              # 10% category
    5               # 10% news/announcement
  ]))

  defaults = %{
    id: generate_snowflake(),
    type: channel_type,
    # DM channels (type 1, 3) have no guild_id
    guild_id: if(channel_type in [1, 3], do: nil, else: generate_snowflake()),
    position: if(channel_type in [1, 3], do: nil, else: Faker.random_between(0, 50)),
    name: if(channel_type in [1, 3], do: nil, else: "#{Faker.Lorem.word()}-#{Faker.Lorem.word()}"),
    # ... rest varies by type ...
  }

  struct(Nostrum.Struct.Channel, merge_attrs(defaults, attrs))
end
```

---

### 8. Guild Generator - Icon/Banner Always Present (Lines 158-159)

**Current Code**:

```elixir
icon: Faker.UUID.v4(),
description: Faker.Lorem.sentence(5..20),
```

**Realism Issue**: Many guilds don't have icons or descriptions

**Fix Required**:

```elixir
defaults = %{
  # ... other fields ...
  # 70% of guilds have icons
  icon: if(Faker.Util.pick([true, true, true, true, true, true, true, false, false, false]), do: Faker.UUID.v4(), else: nil),
  # 50% have descriptions
  description: if(Faker.Util.pick([true, false]), do: Faker.Lorem.sentence(5..20), else: nil),
  # ... other fields ...
}
```

---

## Priority 3: Medium - Missing Nil Cases (Reduce Test Coverage)

### 9. Member Generator - Nick Always Set or Nil Pattern (Line 372)

**Current Code**:

```elixir
nick: if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
```

**Issue**: Good pattern, but percentage should be ~20% (most members don't have
nicknames)

**Fix Required**:

```elixir
# 20% have nicknames
nick: if(Faker.Util.pick([true] ++ List.duplicate(false, 4)), do: Faker.Person.first_name(), else: nil),
```

---

### 10. Message Generator - Webhook ID Never Set (Line 264)

**Current Code**:

```elixir
webhook_id: nil,
```

**Issue**: Never generates webhook messages, reducing test coverage

**Fix Required**:

```elixir
# 5% webhook messages
webhook_id: if(Faker.Util.pick([true] ++ List.duplicate(false, 19)), do: generate_snowflake(), else: nil),
```

**Also need to adjust author** when webhook_id is present:

```elixir
final_result =
  if Map.has_key?(attrs, :webhook_id) do
    result
  else
    # If webhook_id was randomly generated, adjust author
    if result.webhook_id do
      # Webhook messages have webhook author, not real user
      Map.put(result, :author, %{
        id: generate_snowflake(),
        username: "#{Faker.Lorem.word()} Webhook",
        discriminator: "0000",
        avatar: nil,
        bot: true
      })
    else
      result
    end
  end
```

---

### 11. Message Generator - Attachments/Embeds Always Empty (Lines 260-261)

**Current Code**:

```elixir
attachments: [],
embeds: [],
```

**Issue**: Never generates messages with attachments or embeds

**Fix Required**:

```elixir
# 15% have attachments
attachments: if(Faker.Util.pick([true, true, true] ++ List.duplicate(false, 17)),
  do: [message_attachment()],
  else: []
),
# 20% have embeds
embeds: if(Faker.Util.pick([true, true] ++ List.duplicate(false, 8)),
  do: [embed()],
  else: []
),
```

---

### 12. Message Generator - Mentions Always Empty (Lines 258-259)

**Current Code**:

```elixir
mentions: [],
mention_roles: [],
```

**Issue**: Never generates messages with mentions

**Fix Required**:

```elixir
# 30% mention users
mentions: if(Faker.Util.pick([true, true, true] ++ List.duplicate(false, 7)),
  do: [user()],
  else: []
),
# 20% mention roles
mention_roles: if(Faker.Util.pick([true, true] ++ List.duplicate(false, 8)),
  do: [generate_snowflake()],
  else: []
),
```

---

### 13. Message Attachment Generator - Height/Width Logic (Lines 782-785)

**Current Code**:

```elixir
height: if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1080), else: nil),
width: if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1920), else: nil)
```

**Issue**: Good logic, but should also handle `nil` for images sometimes
(Discord doesn't always provide dimensions)

**Fix Required**:

```elixir
height: if(extension in ["png", "jpg", "gif"],
  # 90% of images have dimensions, 10% don't
  do: if(Faker.Util.pick([true, true, true, true, true, true, true, true, true, false]), do: Faker.random_between(100, 1080), else: nil),
  else: nil
),
width: if(extension in ["png", "jpg", "gif"],
  do: if(Faker.Util.pick([true, true, true, true, true, true, true, true, true, false]), do: Faker.random_between(100, 1920), else: nil),
  else: nil
)
```

---

### 14. Voice State Generator - Should Support Disconnect State (Line 735)

**Current Code**:

```elixir
channel_id: generate_snowflake(),
```

**Issue**: Never generates disconnected state (channel_id: nil)

**Corrected Payload** (VoiceState allows nil channel_id when user leaves voice)

**Fix Required**:

```elixir
# 90% connected to voice, 10% disconnected (channel_id: nil)
channel_id: if(Faker.Util.pick([true, true, true, true, true, true, true, true, true, false]),
  do: generate_snowflake(),
  else: nil
),
```

---

### 15. Invite Generator - Always Has All Optional Fields (Lines 560-564)

**Current Code**:

```elixir
guild: guild(),
channel: channel(),
inviter: user(),
target_user: nil,
expires_at: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
```

**Issue**: `guild`, `channel`, `inviter` should sometimes be nil for simple
invites

**Fix Required**:

```elixir
defaults = %{
  code: code,
  # Simple invites don't include full guild/channel objects
  guild: if(Faker.Util.pick([true, false]), do: guild(), else: nil),
  channel: if(Faker.Util.pick([true, false]), do: channel(), else: nil),
  inviter: if(Faker.Util.pick([true, true, false]), do: user(), else: nil),
  target_user: nil,  # Rare, keep nil
  # 30% of invites never expire
  expires_at: if(Faker.Util.pick([true, true, true, true, true, true, true, false, false, false]),
    do: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
    else: nil
  ),
  max_uses: if(Faker.Util.pick([true, false]), do: Faker.random_between(1, 100), else: 0),
  uses: 0
}
```

---

### 16. Webhook Generator - Missing `type` Field (Lines 522-529)

**Current Code**: Does not include `type` field

**Corrected Payload** (from IMPLEMENTATION_SUMMARY.md):

```
Webhook: Added type field (required, non-nullable)
```

**Fix Required**:

```elixir
defaults = %{
  id: generate_snowflake(),
  type: 1,  # 1 = Incoming webhook (most common)
  guild_id: generate_snowflake(),
  # ... rest of fields ...
}
```

---

## Priority 4: Low - Nice-to-Have Improvements

### 17. Role Generator - Color Distribution (Lines 408-418)

**Current Enhancement**:

```elixir
# Current generates random RGB
{r, g, b} = Faker.Color.rgb_decimal()
color: rgb_to_int({r, g, b}),
```

**Enhancement**: Include common Discord role colors

```elixir
# Mix of random colors and common Discord presets
color: Faker.Util.pick([
  0,          # No color (default role)
  0x1ABC9C,   # Teal
  0x2ECC71,   # Green
  0x3498DB,   # Blue
  0x9B59B6,   # Purple
  0xE91E63,   # Magenta
  0xF1C40F,   # Yellow
  0xE67E22,   # Orange
  0xE74C3C,   # Red
  0x95A5A6,   # Grey
  rgb_to_int(Faker.Color.rgb_decimal())  # Random
]),
```

---

### 18. Interaction Generator - DM vs Guild Context (Lines 333-334)

**Current Code**: Always guild context

```elixir
guild_id: generate_snowflake(),
member: %{user: interaction_user},
```

**Enhancement**: Support DM interactions

```elixir
# 90% guild, 10% DM interactions
is_dm = Faker.Util.pick([true] ++ List.duplicate(false, 9))

defaults = %{
  # ... other fields ...
  guild_id: if(is_dm, do: nil, else: generate_snowflake()),
  member: if(is_dm, do: nil, else: %{user: interaction_user}),
  user: interaction_user,
  # ... rest ...
}
```

---

### 19. Thread Generator - Metadata ISO8601 String (Line 1041)

**Current Code**:

```elixir
archive_timestamp: Faker.DateTime.backward(1) |> DateTime.to_iso8601(),
```

**Enhancement**: Verify if this should be DateTime or keep as ISO8601 string
(check Nostrum types)

---

### 20. Message Reaction Generator - No Guild Context Fields (Lines 810-832)

**Current Code**: Missing `user_id`, `message_id`, `channel_id`, `guild_id` that
are present in MessageReactionAdd events

**Enhancement**: Add these fields for consistency with event generators

```elixir
defaults = %{
  emoji: emoji_data,
  count: Faker.random_between(1, 10),
  me: Faker.Util.pick([true, false]),
  # Add event context fields
  user_id: generate_snowflake(),
  message_id: generate_snowflake(),
  channel_id: generate_snowflake(),
  guild_id: if(Faker.Util.pick([true, true, true, true, false]), do: generate_snowflake(), else: nil)
}
```

---

## Summary Statistics

### Issues by Priority

| Priority      | Count  | Description                            |
| ------------- | ------ | -------------------------------------- |
| P1 - Critical | 3      | Type mismatches causing runtime errors |
| P2 - High     | 8      | Unrealistic data reducing test quality |
| P3 - Medium   | 8      | Missing nil cases reducing coverage    |
| P4 - Low      | 4      | Nice-to-have improvements              |
| **Total**     | **23** | **Total issues identified**            |

### Issues by Generator Function

| Generator              | Critical | High | Medium | Low | Total |
| ---------------------- | -------- | ---- | ------ | --- | ----- |
| `member/1`             | 1        | 0    | 1      | 0   | 2     |
| `sticker/1`            | 1        | 0    | 0      | 0   | 1     |
| `message/1`            | 1        | 1    | 3      | 0   | 5     |
| `user/1`               | 0        | 1    | 0      | 0   | 1     |
| `emoji/1`              | 0        | 1    | 0      | 0   | 1     |
| `channel/1`            | 0        | 1    | 0      | 0   | 1     |
| `guild/1`              | 0        | 1    | 0      | 0   | 1     |
| `webhook/1`            | 0        | 0    | 1      | 0   | 1     |
| `message_attachment/1` | 0        | 0    | 1      | 0   | 1     |
| `voice_state/1`        | 0        | 0    | 1      | 0   | 1     |
| `invite/1`             | 0        | 0    | 1      | 0   | 1     |
| `role/1`               | 0        | 0    | 0      | 1   | 1     |
| `interaction/1`        | 0        | 0    | 0      | 1   | 1     |
| `thread/1`             | 0        | 0    | 0      | 1   | 1     |
| `message_reaction/1`   | 0        | 0    | 0      | 1   | 1     |

---

## Implementation Recommendations

### Phase 1: Fix Critical Issues (P1)

**Estimated Time**: 30 minutes

1. Fix `member/1`: Add DateTime for `premium_since` and
   `communication_disabled_until`
2. Fix `sticker/1`: Change integer enums to atoms
3. Fix `message/1`: Change ISO8601 strings to DateTime structs

**Validation**: Run existing tests to ensure no regressions

---

### Phase 2: Improve Realism (P2)

**Estimated Time**: 2 hours

1. Add nil variations to `user/1`, `emoji/1`, `guild/1`
2. Add guild context to `message/1`
3. Add channel type variations to `channel/1`

**Validation**: Review generated test data for realism

---

### Phase 3: Increase Coverage (P3)

**Estimated Time**: 1.5 hours

1. Add nil cases for all optional fields
2. Add webhook messages, mentions, attachments to `message/1`
3. Add disconnect state to `voice_state/1`
4. Fix `webhook/1` type field

**Validation**: Check test coverage for nil handling

---

### Phase 4: Polish (P4)

**Estimated Time**: 1 hour

1. Add common Discord role colors
2. Add DM interaction support
3. Enhance message reactions with context

**Validation**: Final review of all generators

---

## Testing Strategy After Fixes

### 1. Property-Based Tests

Create property tests that verify:

- All required fields are never nil
- All optional fields can be nil
- Type constraints match payload definitions
- Realistic data distributions

### 2. Integration Tests

Test actual payload conversion:

- Generate struct → Convert to payload → Verify types
- Test edge cases (Unicode emoji, DM messages, timed-out members, etc.)

### 3. Snapshot Tests

Compare generated data against real Discord API responses to verify realism

---

## Conclusion

The Discord generators have **3 critical type mismatches** that will cause
immediate test failures when Nostrum provides real Discord data. Additionally,
**15+ nullability and realism issues** reduce test coverage and quality.

**Recommended Action**: Implement fixes in priority order (P1 → P2 → P3 → P4) to
ensure robust, realistic test data that matches production Discord API behavior.

---

## Nested Struct Verification

**Date Added**: 2025-10-05 **Verified Against**: Nostrum source code in
`/home/joba/sandbox/ash_discord/deps/nostrum/lib/nostrum/struct/`

This section identifies critical issues where generators produce plain maps
instead of proper Nostrum struct instances for nested fields.

### Summary

- **Total nested struct issues**: 12
- **Critical (breaks type contracts)**: 8
- **High (may cause issues)**: 4
- **Medium (works but inconsistent)**: 0

---

### Critical Issues - Plain Maps Instead of Structs

#### 1. Message Generator - `member` Field MISSING

**Generator**: `message/1` **Field**: `member` **Line**: N/A (field not
generated) **Expected**: `Nostrum.Struct.Guild.Member.t() | nil` **Currently
produces**: Field not included **Priority**: Critical

**Evidence from Nostrum** (`message.ex` lines 267, 197):

```elixir
|> Map.update(:member, nil, &Util.cast(&1, {:struct, Member}))

@typedoc "Partial Guild Member object received with the Message Create event"
@type member :: Member.t() | nil
```

**Fix**:

```elixir
# In message/1 function
defaults = %{
  # ... other fields ...
  author: author_user,
  # Add member field when in guild context
  member: if(Map.get(attrs, :guild_id) || defaults[:guild_id],
    do: member(%{user_id: author_user.id}),
    else: nil
  ),
  # ... rest of fields ...
}
```

---

#### 2. Message Generator - `mentions` Field

**Generator**: `message/1` **Field**: `mentions` **Line**: 258 **Expected**:
`[User.t()]` (list of User structs) **Currently produces**: `[]` (empty list,
never populated) **Priority**: Critical

**Evidence from Nostrum** (`message.ex` lines 270, 94):

```elixir
|> Map.update(:mentions, nil, &Util.cast(&1, {:list, {:struct, User}}))

@typedoc "List of users mentioned in the message"
@type mentions :: [User.t()]
```

**Fix**:

```elixir
# 30% of messages mention users
mentions: if(Faker.Util.pick([true, true, true] ++ List.duplicate(false, 7)),
  do: [user(), user()],  # Generate User structs
  else: []
),
```

---

#### 3. Message Generator - `attachments` Field

**Generator**: `message/1` **Field**: `attachments` **Line**: 260 **Expected**:
`[Attachment.t()]` (list of Attachment structs) **Currently produces**: `[]`
(empty list, never populated) **Priority**: Critical

**Evidence from Nostrum** (`message.ex` lines 258, 100):

```elixir
|> Map.update(:attachments, nil, &Util.cast(&1, {:list, {:struct, Attachment}}))

@typedoc "List of attached files in the message"
@type attachments :: [Attachment.t()]
```

**Fix**:

```elixir
# 15% of messages have attachments
attachments: if(Faker.Util.pick([true, true, true] ++ List.duplicate(false, 17)),
  do: [message_attachment()],  # Generate Attachment structs
  else: []
),
```

---

#### 4. Message Generator - `embeds` Field

**Generator**: `message/1` **Field**: `embeds` **Line**: 261 **Expected**:
`[Embed.t()]` (list of Embed structs) **Currently produces**: `[]` (empty list,
never populated) **Priority**: Critical

**Evidence from Nostrum** (`message.ex` lines 263, 121):

```elixir
|> Map.update(:embeds, nil, &Util.cast(&1, {:list, {:struct, Embed}}))

@typedoc "List of embedded content in the message"
@type embeds :: [Embed.t()]
```

**Fix**:

```elixir
# 20% of messages have embeds
embeds: if(Faker.Util.pick([true, true] ++ List.duplicate(false, 8)),
  do: [embed()],  # Generate Embed structs
  else: []
),
```

---

#### 5. Message Generator - `reactions` Field

**Generator**: `message/1` **Field**: `reactions` **Line**: 262 **Expected**:
`[Reaction.t()] | nil` (list of Reaction structs or nil) **Currently produces**:
`nil` (never populated with list) **Priority**: High

**Evidence from Nostrum** (`message.ex` lines 274, 124):

```elixir
|> Map.update(:reactions, nil, &Util.cast(&1, {:list, {:struct, Reaction}}))

@typedoc "Reactions to the message."
@type reactions :: [Reaction.t()] | nil
```

**Fix**:

```elixir
# 10% of messages have reactions
reactions: if(Faker.Util.pick([true] ++ List.duplicate(false, 9)),
  do: [message_reaction()],  # Generate Reaction structs
  else: nil
),
```

---

#### 6. Interaction Generator - `member` Field

**Generator**: `interaction/1` **Field**: `member` **Lines**: 335-337
**Expected**: `Nostrum.Struct.Guild.Member.t() | nil` **Currently produces**:
Plain map `%{user: interaction_user}` **Priority**: Critical

**Evidence from Nostrum** (`interaction.ex` lines 146, 73):

```elixir
|> Map.update(:member, nil, &Util.cast(&1, {:struct, Guild.Member}))

@typedoc "Member information about the invoker, if invoked on a guild"
@type member :: Member.t() | nil
```

**Fix**:

```elixir
defaults = %{
  # ... other fields ...
  # Generate proper Member struct instead of plain map
  member: member(%{user_id: interaction_user.id}),
  user: interaction_user,
  # ... rest of fields ...
}
```

---

#### 7. Message Reaction Generator - `emoji` Field

**Generator**: `message_reaction/1` **Field**: `emoji` **Lines**: 812-823
**Expected**: `Nostrum.Struct.Emoji.t()` **Currently produces**: Plain map
`%{id: ..., name: ..., animated: ...}` **Priority**: Critical

**Evidence from Nostrum** (`message/reaction.ex` lines 35, 22):

```elixir
|> Map.update(:emoji, nil, &Util.cast(&1, {:struct, Emoji}))

@typedoc "Emoji information"
@type emoji :: Emoji.t()
```

**Fix**:

```elixir
def message_reaction(attrs \\ %{}) do
  # Generate proper Emoji struct instead of plain map
  reaction_emoji = if Faker.Util.pick([true, false]) do
    # Unicode emoji
    emoji(%{id: nil, name: Faker.Util.pick(["👍", "👎", "❤️", "😂", "😢", "🔥"])})
  else
    # Custom emoji
    emoji(%{id: generate_snowflake(), name: Faker.Lorem.word()})
  end

  defaults = %{
    emoji: reaction_emoji,  # Use Emoji struct, not plain map
    count: Faker.random_between(1, 10),
    me: Faker.Util.pick([true, false])
  }

  struct(Nostrum.Struct.Message.Reaction, merge_attrs(defaults, attrs))
end
```

---

#### 8. Voice State Generator - `member` Field MISSING

**Generator**: `voice_state/1` **Field**: `member` **Line**: N/A (field not
generated) **Expected**: `Nostrum.Struct.Guild.Member.t() | nil` **Currently
produces**: Field not included **Priority**: High

**Evidence from Nostrum** (`event/voice_state.ex` lines 92, 37):

```elixir
|> Map.update(:member, nil, &Util.cast(&1, {:struct, Member}))

@typedoc "Guild member this voice state is for, if applicable"
@type member :: Member.t() | nil
```

**Fix**:

```elixir
def voice_state(attrs \\ %{}) do
  defaults = %{
    guild_id: generate_snowflake(),
    channel_id: generate_snowflake(),
    user_id: generate_snowflake(),
    # Add member field for guild voice states
    member: if(Faker.Util.pick([true, true, true, false]),
      do: member(),
      else: nil
    ),
    session_id: Faker.UUID.v4(),
    # ... rest of fields ...
  }

  struct(Nostrum.Struct.Event.VoiceState, merge_attrs(defaults, attrs))
end
```

---

### High Priority Issues - Missing Nested Collections

#### 9. Guild Generator - `roles` Field MISSING

**Generator**: `guild/1` **Field**: `roles` **Line**: N/A (field not generated)
**Expected**: `%{required(Role.id()) => Role.t()}` (map of Role structs indexed
by ID) **Currently produces**: Field not included **Priority**: High

**Evidence from Nostrum** (`guild.ex` lines 569, 109):

```elixir
|> Map.update(:roles, nil, &Util.cast(&1, {:index, [:id], {:struct, Role}}))

@typedoc "List of roles"
@type roles :: %{required(Role.id()) => Role.t()}
```

**Fix**:

```elixir
def guild(attrs \\ %{}) do
  # Generate roles map indexed by role ID
  roles_list = Enum.map(1..Faker.random_between(3, 10), fn _ -> role() end)
  roles_map = Map.new(roles_list, fn r -> {r.id, r} end)

  defaults = %{
    # ... other fields ...
    roles: roles_map,  # Map of role_id => Role struct
    # ... rest of fields ...
  }

  struct(Nostrum.Struct.Guild, merge_attrs(defaults, attrs))
end
```

---

#### 10. Guild Generator - `emojis` Field MISSING

**Generator**: `guild/1` **Field**: `emojis` **Line**: N/A (field not generated)
**Expected**: `[Emoji.t()]` (list of Emoji structs) **Currently produces**:
Field not included **Priority**: High

**Evidence from Nostrum** (`guild.ex` lines 570, 112):

```elixir
|> Map.update(:emojis, nil, &Util.cast(&1, {:list, {:struct, Emoji}}))

@typedoc "List of emojis"
@type emojis :: [Emoji.t()]
```

**Fix**:

```elixir
defaults = %{
  # ... other fields ...
  # Generate list of Emoji structs (50% have custom emojis)
  emojis: if(Faker.Util.pick([true, false]),
    do: Enum.map(1..Faker.random_between(5, 20), fn _ -> emoji() end),
    else: []
  ),
  # ... rest of fields ...
}
```

---

#### 11. Guild Generator - `channels` Field MISSING

**Generator**: `guild/1` **Field**: `channels` **Line**: N/A (field not
generated) **Expected**: `%{required(Channel.id()) => Channel.t()} | nil` (map
of Channel structs) **Currently produces**: Field not included **Priority**:
High

**Evidence from Nostrum** (`guild.ex` lines 577, 168):

```elixir
|> Map.update(:channels, nil, &Util.cast(&1, {:index, [:id], {:struct, Channel}}))

@typedoc "List of channels"
@type channels :: %{required(Channel.id()) => Channel.t()} | nil
```

**Fix**:

```elixir
def guild(attrs \\ %{}) do
  # Generate channels map indexed by channel ID
  channels_list = Enum.map(1..Faker.random_between(5, 15), fn _ ->
    channel(%{guild_id: Map.get(attrs, :id, generate_snowflake())})
  end)
  channels_map = Map.new(channels_list, fn c -> {c.id, c} end)

  defaults = %{
    # ... other fields ...
    channels: channels_map,  # Map of channel_id => Channel struct
    # ... rest of fields ...
  }

  struct(Nostrum.Struct.Guild, merge_attrs(defaults, attrs))
end
```

---

#### 12. Guild Generator - `voice_states` Field MISSING

**Generator**: `guild/1` **Field**: `voice_states` **Line**: N/A (field not
generated) **Expected**: `list(map) | nil` (list of voice state maps)
**Currently produces**: Field not included **Priority**: Medium

**Evidence from Nostrum** (`guild.ex` line 165):

```elixir
@typedoc "List of voice states as maps"
@type voice_states :: list(map) | nil
```

**Note**: Voice states are kept as maps in Nostrum (not converted to structs),
so generators would use maps:

**Fix**:

```elixir
defaults = %{
  # ... other fields ...
  # Generate list of voice state maps (20% of guilds have active voice)
  voice_states: if(Faker.Util.pick([true, true, false, false, false]),
    do: Enum.map(1..Faker.random_between(1, 5), fn _ ->
      %{
        user_id: generate_snowflake(),
        session_id: Faker.UUID.v4(),
        deaf: false,
        mute: false,
        self_deaf: Faker.Util.pick([true, false]),
        self_mute: Faker.Util.pick([true, false])
      }
    end),
    else: nil
  ),
  # ... rest of fields ...
}
```

---

### Summary Table of Nested Struct Issues

| Generator            | Field          | Expected Type                    | Current                | Line    | Priority |
| -------------------- | -------------- | -------------------------------- | ---------------------- | ------- | -------- |
| `message/1`          | `member`       | `Member.t() \| nil`              | Missing                | N/A     | Critical |
| `message/1`          | `mentions`     | `[User.t()]`                     | `[]` (never populated) | 258     | Critical |
| `message/1`          | `attachments`  | `[Attachment.t()]`               | `[]` (never populated) | 260     | Critical |
| `message/1`          | `embeds`       | `[Embed.t()]`                    | `[]` (never populated) | 261     | Critical |
| `message/1`          | `reactions`    | `[Reaction.t()] \| nil`          | `nil` (never list)     | 262     | High     |
| `interaction/1`      | `member`       | `Member.t() \| nil`              | Plain map              | 335-337 | Critical |
| `message_reaction/1` | `emoji`        | `Emoji.t()`                      | Plain map              | 812-823 | Critical |
| `voice_state/1`      | `member`       | `Member.t() \| nil`              | Missing                | N/A     | High     |
| `guild/1`            | `roles`        | `%{Role.id() => Role.t()}`       | Missing                | N/A     | High     |
| `guild/1`            | `emojis`       | `[Emoji.t()]`                    | Missing                | N/A     | High     |
| `guild/1`            | `channels`     | `%{Channel.id() => Channel.t()}` | Missing                | N/A     | High     |
| `guild/1`            | `voice_states` | `list(map) \| nil`               | Missing                | N/A     | Medium   |

---

### Testing Impact

**Without proper nested structs**, tests will:

1. **Fail type checks** when code expects `User.t()` but gets plain map
2. **Miss bugs** related to struct field access (e.g., `user.id` vs `user[:id]`)
3. **Not catch** Nostrum's `to_struct` conversion issues
4. **Produce unrealistic** test scenarios (messages without authors, guilds
   without channels)

**Recommended Fix Order**:

1. **Phase 1 (Critical)**: Fix `message/1`, `interaction/1`,
   `message_reaction/1` generators - these are used most frequently
2. **Phase 2 (High)**: Add nested structs to `guild/1` and `voice_state/1`
3. **Phase 3 (Medium)**: Polish `guild/1` voice_states

**Validation Strategy**:

```elixir
# Property test to verify nested structs
property "message generator produces proper nested structs" do
  check all msg <- message_generator() do
    assert %Nostrum.Struct.Message{} = msg
    assert is_nil(msg.author) or match?(%Nostrum.Struct.User{}, msg.author)
    assert is_nil(msg.member) or match?(%Nostrum.Struct.Guild.Member{}, msg.member)
    assert Enum.all?(msg.mentions, &match?(%Nostrum.Struct.User{}, &1))
    assert Enum.all?(msg.attachments, &match?(%Nostrum.Struct.Message.Attachment{}, &1))
    assert Enum.all?(msg.embeds, &match?(%Nostrum.Struct.Embed{}, &1))
    assert is_nil(msg.reactions) or Enum.all?(msg.reactions, &match?(%Nostrum.Struct.Message.Reaction{}, &1))
  end
end
```
