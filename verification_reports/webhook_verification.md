# Webhook Payload Verification Report

**Date**: 2025-10-05 **File**:
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/webhook.ex`
**Discord API Reference**:
https://discord.com/developers/docs/resources/webhook#webhook-object **Discord
API Types Reference**:
https://discord-api-types.dev/api/discord-api-types-v10/interface/APIWebhook
**Nostrum Reference**: Nostrum.Struct.Webhook

---

## Executive Summary

The current Webhook payload implementation includes 11 fields out of 12 fields
available in the Discord API Webhook Object. The implementation largely matches
the Nostrum.Struct.Webhook fields but has several critical issues with field
types and `allow_nil?` settings.

### Current Status

- **Total Discord API Fields**: 12
- **Implemented Fields**: 11
- **Missing Fields**: 1 (type)
- **Type Mismatches**: 4 fields (id, name, avatar, token - Nostrum has incorrect
  type annotations)
- **allow_nil? Issues**: 10 fields need correction
- **Extra Fields**: 0

---

## Field-by-Field Analysis

### ⚠️ Fields Needing Corrections

#### 1. `id`

- **Current**:
  `field :id, :integer, allow_nil?: false, description: "Webhook id"`
- **Discord API**: `id: string` (required, non-nullable)
- **Nostrum**: `id: String.t()` (but Nostrum's @typedoc says `String.t()`, not
  integer)
- **Issue**: Type mismatch - Discord uses string for snowflake IDs
- **Status**: ⚠️ ACCEPTABLE (Common to store snowflakes as integers in Elixir,
  but technically incorrect per API spec)
- **Recommendation**: Keep as `:integer` to match common Elixir practice, but
  document this conversion
- **Correct Implementation**:

```elixir
field :id, :integer,
  allow_nil?: false,
  description: "The id of the webhook (snowflake)"
```

#### 2. `name`

- **Current**: `field :name, :string, description: "Webhook name"`
- **Discord API**: `name: null | string` (required but nullable)
- **Nostrum**: `name: integer` (NOTE: Nostrum's type annotation appears
  INCORRECT - should be string)
- **Issue**: Missing `allow_nil?: true` (field is nullable)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :name, :string,
  allow_nil?: true,
  description: "The default name of the webhook"
```

#### 3. `avatar`

- **Current**: `field :avatar, :string, description: "Webhook avatar hash"`
- **Discord API**: `avatar: null | string` (required but nullable)
- **Nostrum**: `avatar: integer` (NOTE: Nostrum's type annotation appears
  INCORRECT - should be string)
- **Issue**: Missing `allow_nil?: true` (field is nullable)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :avatar, :string,
  allow_nil?: true,
  description: "The default avatar of the webhook (avatar hash)"
```

#### 4. `token`

- **Current**:
  `field :token, :string, description: "Secure token for the webhook"`
- **Discord API**: `token?: string` (optional)
- **Nostrum**: `token: integer` (NOTE: Nostrum's type annotation appears
  INCORRECT - should be string)
- **Issue**: Missing `allow_nil?: true` (field is optional)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :token, :string,
  allow_nil?: true,
  description: "The secure token of the webhook (returned for Incoming Webhooks)"
```

#### 5. `channel_id`

- **Current**:
  `field :channel_id, :integer, description: "Channel id this webhook is for"`
- **Discord API**: `channel_id: string` (required, non-nullable)
- **Nostrum**: `channel_id: Channel.t()`
- **Issue**: Missing `allow_nil?: false` (should be explicit)
- **Status**: ⚠️ NEEDS EXPLICIT SETTING
- **Recommended Fix**:

```elixir
field :channel_id, :integer,
  allow_nil?: false,
  description: "The channel id this webhook is for (snowflake)"
```

#### 6. `guild_id`

- **Current**:
  `field :guild_id, :integer, description: "Guild id this webhook is for"`
- **Discord API**: `guild_id?: string` (optional)
- **Nostrum**: `guild_id: Guild.t()`
- **Issue**: Missing `allow_nil?: true` (field is optional - not present for
  webhook followers)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :guild_id, :integer,
  allow_nil?: true,
  description: "The guild id this webhook is for (snowflake), if available"
```

#### 7. `user`

- **Current**:
  `field :user, :map, description: "User object of the webhook creator"`
- **Discord API**: `user?: APIUser` (optional)
- **Nostrum**: `user: User.t()`
- **Issue**: Missing `allow_nil?: true` (field is optional - not returned when
  getting a webhook with its token)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :user, :map,
  allow_nil?: true,
  description: "The user this webhook was created by (not returned when getting a webhook with its token)"
```

#### 8. `application_id`

- **Current**:
  `field :application_id, :integer, description: "Bot/OAuth2 application id"`
- **Discord API**: `application_id: null | string` (required but nullable)
- **Issue**: Missing `allow_nil?: true` (field is nullable)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :application_id, :integer,
  allow_nil?: true,
  description: "The bot/OAuth2 application that created this webhook (snowflake)"
```

#### 9. `source_guild`

- **Current**:
  `field :source_guild, :map, description: "Partial guild object for webhooks created from server following"`
- **Discord API**: `source_guild?: APIWebhookSourceGuild` (optional)
- **Issue**: Missing `allow_nil?: true` (field is optional)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :source_guild, :map,
  allow_nil?: true,
  description: "The guild of the channel that this webhook is following (partial guild object for Channel Follower Webhooks)"
```

#### 10. `source_channel`

- **Current**:
  `field :source_channel, :map, description: "Partial channel object for webhooks created from server following"`
- **Discord API**:
  `source_channel?: Required<Pick<APIPartialChannel, 'id' | 'name'>>` (optional)
- **Issue**: Missing `allow_nil?: true` (field is optional)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :source_channel, :map,
  allow_nil?: true,
  description: "The channel that this webhook is following (partial channel object with id and name for Channel Follower Webhooks)"
```

#### 11. `url`

- **Current**:
  `field :url, :string, description: "URL for executing the webhook"`
- **Discord API**: `url?: string` (optional)
- **Issue**: Missing `allow_nil?: true` (field is optional - returned by the
  webhooks OAuth2 flow)
- **Status**: ❌ NEEDS CORRECTION
- **Recommended Fix**:

```elixir
field :url, :string,
  allow_nil?: true,
  description: "The url used for executing the webhook (returned by the webhooks OAuth2 flow)"
```

---

## Missing Fields from Discord API

The following field is available in the Discord API but not currently captured
in the Webhook payload.

### Missing Field

#### 12. `type`

- **Discord API**: `type: WebhookType` (required, non-nullable)
- **Description**: The type of the webhook
- **Webhook Types**:
  - 1 = Incoming (created via "Create Webhook" button in channel settings)
  - 2 = Channel Follower (created via Channel Following)
  - 3 = Application (application webhooks are webhooks used with Interactions)
- **Note**: This field is NOT in Nostrum.Struct.Webhook
- **Status**: ❌ MISSING
- **Recommended Addition**:

```elixir
field :type, :integer,
  allow_nil?: false,
  description: "The type of the webhook (1 = Incoming, 2 = Channel Follower, 3 = Application)"
```

**Why this matters**: The `type` field is critical for understanding webhook
behavior:

- Type 1 (Incoming): Can be used by anyone with the token
- Type 2 (Channel Follower): Automatically created when following a channel
- Type 3 (Application): Used for Discord Interactions

---

## Extra Fields Analysis

**No extra fields found.** All current fields exist in the Discord API Webhook
Object.

---

## Nostrum Type Annotation Issues

**IMPORTANT**: The Nostrum.Struct.Webhook module has several incorrect type
annotations that should be noted:

```elixir
# Nostrum's INCORRECT annotations:
@type name :: integer    # Should be: String.t() | nil
@type avatar :: integer  # Should be: String.t() | nil
@type token :: integer   # Should be: String.t() | nil
```

These appear to be typos in the Nostrum library. The actual runtime values are
strings, not integers. Our implementation correctly uses `:string` type.

---

## Recommended Changes

### Complete Corrected Implementation

```elixir
defmodule AshDiscord.Consumer.Payloads.Webhook do
  @moduledoc """
  TypedStruct wrapper for Discord Webhook data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Webhook.t()`,
  plus the `type` field from the Discord API.

  ## References
  - [Discord API - Webhook](https://discord.com/developers/docs/resources/webhook#webhook-object)
  - [Nostrum - Webhook](https://hexdocs.pm/nostrum/Nostrum.Struct.Webhook.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "The id of the webhook (snowflake)"

    field :type, :integer,
      allow_nil?: false,
      description: "The type of the webhook (1 = Incoming, 2 = Channel Follower, 3 = Application)"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "The guild id this webhook is for (snowflake), if available"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "The channel id this webhook is for (snowflake)"

    field :user, :map,
      allow_nil?: true,
      description: "The user this webhook was created by (not returned when getting a webhook with its token)"

    field :name, :string,
      allow_nil?: true,
      description: "The default name of the webhook"

    field :avatar, :string,
      allow_nil?: true,
      description: "The default avatar of the webhook (avatar hash)"

    field :token, :string,
      allow_nil?: true,
      description: "The secure token of the webhook (returned for Incoming Webhooks)"

    field :application_id, :integer,
      allow_nil?: true,
      description: "The bot/OAuth2 application that created this webhook (snowflake)"

    field :source_guild, :map,
      allow_nil?: true,
      description: "The guild of the channel that this webhook is following (partial guild object for Channel Follower Webhooks)"

    field :source_channel, :map,
      allow_nil?: true,
      description: "The channel that this webhook is following (partial channel object with id and name for Channel Follower Webhooks)"

    field :url, :string,
      allow_nil?: true,
      description: "The url used for executing the webhook (returned by the webhooks OAuth2 flow)"
  end

  @doc """
  Create a Webhook TypedStruct from a Nostrum Webhook struct.

  Accepts a `Nostrum.Struct.Webhook.t()` and creates an AshDiscord Webhook TypedStruct.
  Also handles being passed a Webhook payload (no-op for already-converted payloads) or a raw map for validation.

  Note: Nostrum.Struct.Webhook does not include the `type` field, so it will be nil when converting from Nostrum.
  """
  def new(%__MODULE__{} = webhook_payload) do
    {:ok, webhook_payload}
  end

  def new(%Nostrum.Struct.Webhook{} = nostrum_webhook) do
    super(Map.from_struct(nostrum_webhook))
  end

  def new(value) do
    super(value)
  end
end
```

---

## Discord API Nullable vs Optional Semantics

Understanding Discord's field markings:

1. **`field?` (optional field)**: May not be present in the response →
   `allow_nil?: true`
2. **`?type` or `null | type` (nullable type)**: Present but may be null →
   `allow_nil?: true`
3. **`field? ?type` or `field?: null | type` (both)**: May not be present OR may
   be null → `allow_nil?: true`
4. **`field type` (neither)**: Always present and non-null → `allow_nil?: false`

### Applied to Webhook Fields:

| Field            | Discord API                            | Elixir Setting      | Reason                             |
| ---------------- | -------------------------------------- | ------------------- | ---------------------------------- |
| `id`             | `id: string`                           | `allow_nil?: false` | Required, non-nullable             |
| `type`           | `type: WebhookType`                    | `allow_nil?: false` | Required, non-nullable             |
| `guild_id`       | `guild_id?: string`                    | `allow_nil?: true`  | Optional (missing for followers)   |
| `channel_id`     | `channel_id: string`                   | `allow_nil?: false` | Required, non-nullable             |
| `user`           | `user?: APIUser`                       | `allow_nil?: true`  | Optional (not returned with token) |
| `name`           | `name: null \| string`                 | `allow_nil?: true`  | Nullable                           |
| `avatar`         | `avatar: null \| string`               | `allow_nil?: true`  | Nullable                           |
| `token`          | `token?: string`                       | `allow_nil?: true`  | Optional                           |
| `application_id` | `application_id: null \| string`       | `allow_nil?: true`  | Nullable                           |
| `source_guild`   | `source_guild?: APIWebhookSourceGuild` | `allow_nil?: true`  | Optional                           |
| `source_channel` | `source_channel?: Required<...>`       | `allow_nil?: true`  | Optional                           |
| `url`            | `url?: string`                         | `allow_nil?: true`  | Optional                           |

---

## Recommendations Summary

### Immediate Actions (Required)

1. ✅ Add `type` field (required, non-nullable)
2. ✅ Add `allow_nil?: true` to `name` field (nullable)
3. ✅ Add `allow_nil?: true` to `avatar` field (nullable)
4. ✅ Add `allow_nil?: true` to `token` field (optional)
5. ✅ Add `allow_nil?: true` to `guild_id` field (optional)
6. ✅ Add `allow_nil?: true` to `user` field (optional)
7. ✅ Add `allow_nil?: true` to `application_id` field (nullable)
8. ✅ Add `allow_nil?: true` to `source_guild` field (optional)
9. ✅ Add `allow_nil?: true` to `source_channel` field (optional)
10. ✅ Add `allow_nil?: true` to `url` field (optional)
11. ✅ Set explicit `allow_nil?: false` on `channel_id` field (required)
12. ✅ Improve field descriptions to match Discord API documentation

### Notes

- The current implementation matches Nostrum.Struct.Webhook except for the
  missing `type` field
- Nostrum has incorrect type annotations (`integer` instead of `String.t()`) for
  `name`, `avatar`, and `token`
- Our implementation correctly uses `:string` type for these fields
- The `type` field is critical for webhook classification and should be added
- Most fields are optional or nullable, only `id`, `type`, and `channel_id` are
  always present

---

## Testing Recommendations

1. **Test nil handling**: Verify that all fields marked `allow_nil?: true`
   properly handle nil values
2. **Test Nostrum compatibility**: Ensure `new(%Nostrum.Struct.Webhook{})` still
   works correctly
3. **Test missing fields**: Verify behavior when Discord doesn't send optional
   fields (`guild_id`, `user`, `token`, etc.)
4. **Test null values**: Verify behavior when Discord sends `null` for nullable
   fields (`name`, `avatar`, `application_id`)
5. **Test webhook types**: Test with all three webhook types (1=Incoming,
   2=Channel Follower, 3=Application)
6. **Test token-based webhooks**: Verify that `user` is not present when
   fetching with token
7. **Test OAuth2 webhooks**: Verify that `url` is present when using OAuth2 flow

---

## References

- Discord API Documentation:
  https://discord.com/developers/docs/resources/webhook#webhook-object
- Discord API Types (TypeScript):
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APIWebhook
- Nostrum Webhook Struct: https://hexdocs.pm/nostrum/Nostrum.Struct.Webhook.html
- Nostrum Source:
  `/home/joba/sandbox/ash_discord/deps/nostrum/lib/nostrum/struct/webhook.ex`
