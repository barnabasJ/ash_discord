# AutoModerationRule Payload Verification Report

**Date**: 2025-10-05 **File**:
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/auto_moderation_rule.ex`
**Discord API Reference**:
https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
**Status**: ⚠️ **ISSUES FOUND** - Multiple fields have incorrect `allow_nil?`
settings

---

## Summary

This verification compared the AutoModerationRule TypedStruct implementation
against the official Discord API documentation. The analysis revealed **3 fields
with incorrect `allow_nil?` settings** that need to be corrected.

### Issues Found

- ✅ **11 fields total** - All field names and types are correct
- ❌ **3 fields** - Have incorrect `allow_nil?` settings
- ✅ **0 missing fields** - All Discord API fields are present
- ✅ **0 extra fields** - No extra fields beyond Discord API spec

---

## Field-by-Field Analysis

### ✅ Correct Fields (8 fields)

These fields match the Discord API specification exactly:

| Field          | Type             | allow_nil? | Discord API Status     | Status     |
| -------------- | ---------------- | ---------- | ---------------------- | ---------- |
| `id`           | `:integer`       | `false`    | Required, non-nullable | ✅ Correct |
| `guild_id`     | `:integer`       | `false`    | Required, non-nullable | ✅ Correct |
| `name`         | `:string`        | `false`    | Required, non-nullable | ✅ Correct |
| `creator_id`   | `:integer`       | `false`    | Required, non-nullable | ✅ Correct |
| `event_type`   | `:integer`       | `false`    | Required, non-nullable | ✅ Correct |
| `trigger_type` | `:integer`       | `false`    | Required, non-nullable | ✅ Correct |
| `actions`      | `{:array, :map}` | `false`    | Required, non-nullable | ✅ Correct |
| `enabled`      | `:boolean`       | `false`    | Required, non-nullable | ✅ Correct |

---

## ❌ Fields Requiring Corrections (3 fields)

### 1. `trigger_metadata` - Missing `allow_nil?: true`

**Current Implementation** (Line 32-33):

```elixir
field :trigger_metadata, :map,
  description: "Additional metadata used to determine whether a rule should be triggered"
```

**Issue**: According to Discord API documentation, `trigger_metadata` is marked
as **optional**. When `allow_nil?` is not specified, it defaults to `false`,
making this field required.

**Discord API Reference**:

- **Type**: object
- **Status**: Optional (can be omitted based on trigger_type)
- **Description**: "the rule trigger metadata"

**Required Fix**:

```elixir
field :trigger_metadata, :map,
  allow_nil?: true,
  description: "Additional metadata used to determine whether a rule should be triggered (optional)"
```

**Reasoning**:

- Discord API marks this field as optional (not all trigger types require
  metadata)
- The field can be `nil` when not applicable to the trigger type
- Should explicitly set `allow_nil?: true` to match API spec

---

### 2. `exempt_roles` - Missing `allow_nil?: true`

**Current Implementation** (Line 43-45):

```elixir
field :exempt_roles, {:array, :integer},
  allow_nil?: false,
  description: "Roles that should not be affected by the rule"
```

**Issue**: According to Discord API documentation, `exempt_roles` is marked as
**optional**. Current implementation incorrectly requires this field.

**Discord API Reference**:

- **Type**: array of snowflakes
- **Status**: Optional
- **Description**: "the role ids that should not be affected by the rule
  (Maximum of 20)"

**Required Fix**:

```elixir
field :exempt_roles, {:array, :integer},
  allow_nil?: true,
  description: "Roles that should not be affected by the rule (optional, maximum of 20)"
```

**Reasoning**:

- Discord API marks this field as optional (not all rules need role exemptions)
- The field can be `nil` when no roles are exempted
- Should set `allow_nil?: true` to match API spec
- Added maximum limit to description for clarity

---

### 3. `exempt_channels` - Missing `allow_nil?: true`

**Current Implementation** (Line 47-49):

```elixir
field :exempt_channels, {:array, :integer},
  allow_nil?: false,
  description: "Channels that should not be affected by the rule"
```

**Issue**: According to Discord API documentation, `exempt_channels` is marked
as **optional**. Current implementation incorrectly requires this field.

**Discord API Reference**:

- **Type**: array of snowflakes
- **Status**: Optional
- **Description**: "the channel ids that should not be affected by the rule
  (Maximum of 50)"

**Required Fix**:

```elixir
field :exempt_channels, {:array, :integer},
  allow_nil?: true,
  description: "Channels that should not be affected by the rule (optional, maximum of 50)"
```

**Reasoning**:

- Discord API marks this field as optional (not all rules need channel
  exemptions)
- The field can be `nil` when no channels are exempted
- Should set `allow_nil?: true` to match API spec
- Added maximum limit to description for clarity

---

## Complete Corrected TypedStruct

Here's the complete corrected `typed_struct` block with all fixes applied:

```elixir
typed_struct do
  field :id, :integer, allow_nil?: false, description: "ID of the rule"
  field :guild_id, :integer, allow_nil?: false, description: "Guild ID this rule belongs to"
  field :name, :string, allow_nil?: false, description: "Name of the rule"

  field :creator_id, :integer,
    allow_nil?: false,
    description: "User ID which created the rule"

  field :event_type, :integer,
    allow_nil?: false,
    description: "Indicates in what event context a rule should be checked (1 = message send)"

  field :trigger_type, :integer,
    allow_nil?: false,
    description:
      "Characterizes the type of content which can trigger the rule (1 = keyword, 3 = spam, 4 = keyword preset, 5 = mention spam, 6 = member profile)"

  field :trigger_metadata, :map,
    allow_nil?: true,
    description: "Additional metadata used to determine whether a rule should be triggered (optional)"

  field :actions, {:array, :map},
    allow_nil?: false,
    description: "Actions which will execute when the rule is triggered"

  field :enabled, :boolean,
    allow_nil?: false,
    description: "Whether the rule is enabled"

  field :exempt_roles, {:array, :integer},
    allow_nil?: true,
    description: "Roles that should not be affected by the rule (optional, maximum of 20)"

  field :exempt_channels, {:array, :integer},
    allow_nil?: true,
    description: "Channels that should not be affected by the rule (optional, maximum of 50)"
end
```

---

## Discord API Field Reference

Based on the official Discord API documentation at
https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object:

| Field              | Type                    | Required/Optional | Description                                                             |
| ------------------ | ----------------------- | ----------------- | ----------------------------------------------------------------------- |
| `id`               | snowflake               | Required          | the id of this rule                                                     |
| `guild_id`         | snowflake               | Required          | the id of the guild which this rule belongs to                          |
| `name`             | string                  | Required          | the rule name                                                           |
| `creator_id`       | snowflake               | Required          | the user which first created this rule                                  |
| `event_type`       | integer                 | Required          | the rule event type                                                     |
| `trigger_type`     | integer                 | Required          | the rule trigger type                                                   |
| `trigger_metadata` | object                  | **Optional**      | the rule trigger metadata                                               |
| `actions`          | array of action objects | Required          | the actions which will execute when the rule is triggered               |
| `enabled`          | boolean                 | Required          | whether the rule is enabled                                             |
| `exempt_roles`     | array of snowflakes     | **Optional**      | the role ids that should not be affected by the rule (Maximum of 20)    |
| `exempt_channels`  | array of snowflakes     | **Optional**      | the channel ids that should not be affected by the rule (Maximum of 50) |

---

## Recommendations

### Immediate Actions Required

1. **Update `trigger_metadata` field**: Add `allow_nil?: true` and update
   description to indicate it's optional
2. **Update `exempt_roles` field**: Change `allow_nil?: false` to
   `allow_nil?: true` and update description to include maximum limit
3. **Update `exempt_channels` field**: Change `allow_nil?: false` to
   `allow_nil?: true` and update description to include maximum limit

### Data Handling Considerations

With these changes, code that uses this payload should be prepared to handle:

- `trigger_metadata` may be `nil` for certain trigger types
- `exempt_roles` may be `nil` when no roles are exempted (or could be an empty
  array)
- `exempt_channels` may be `nil` when no channels are exempted (or could be an
  empty array)

### Testing Recommendations

After making these corrections:

1. Test with auto moderation rules that have no `trigger_metadata` (for
   applicable trigger types)
2. Test with rules that have empty or nil `exempt_roles`
3. Test with rules that have empty or nil `exempt_channels`
4. Verify that the `new/1` function correctly handles nil values for these
   optional fields

---

## Type System Notes

### Understanding `allow_nil?` in TypedStruct

- `allow_nil?: false` (default) - Field is **required** and cannot be `nil`
- `allow_nil?: true` - Field is **optional** and can be `nil`

### Discord API Conventions

- **Required fields**: Must always be present, never `nil`
- **Optional fields**: May be omitted or `nil` depending on context
- **Arrays**: Can be empty `[]` or `nil` when optional

### Snowflake Type Mapping

Discord uses `snowflake` (string representation of 64-bit integer) for IDs. In
this codebase:

- Snowflakes are mapped to `:integer` type in TypedStruct
- This matches the Nostrum library convention

---

## Verification Methodology

This verification was performed by:

1. **Reading current implementation**: Analyzed the TypedStruct definition in
   `/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/auto_moderation_rule.ex`
2. **Fetching Discord API docs**: Retrieved official specification from
   https://raw.githubusercontent.com/discord/discord-api-docs/main/docs/resources/auto-moderation.mdx
3. **Cross-referencing discord-api-types**: Validated against TypeScript
   definitions at
   https://discord-api-types.dev/api/discord-api-types-v10/interface/APIAutoModerationRule
4. **Checking Nostrum implementation**: Reviewed
   Nostrum.Struct.AutoModerationRule.t() at
   https://hexdocs.pm/nostrum/Nostrum.Struct.AutoModerationRule.html
5. **Field-by-field comparison**: Systematically compared each field for name,
   type, and nullability

---

## Conclusion

The AutoModerationRule payload implementation is **mostly correct** with **3
fields requiring corrections** to properly match the Discord API specification.
All corrections involve updating `allow_nil?` settings to properly reflect which
fields are optional according to Discord's API documentation.

**Priority**: Medium - These corrections ensure proper handling of auto
moderation rules that don't use all optional features.

**Impact**: Low to Medium - Existing code may work if Discord always returns
these fields (even as empty arrays), but the corrections ensure compliance with
the API spec and proper handling of all cases.
