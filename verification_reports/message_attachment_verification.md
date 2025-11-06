# MessageAttachment Payload Verification Report

**File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/message_attachment.ex`

**Discord API Reference:**
https://discord.com/developers/docs/resources/message#attachment-object

**Verification Date:** 2025-10-05

---

## Summary

The MessageAttachment payload is **incomplete** and has several issues:

- **7 missing fields** from Discord API
- **1 incorrect field type** (id should be string, not integer)
- **1 incorrect allow_nil? setting** (proxy_url should be required)

---

## Field-by-Field Comparison

### ✅ Correct Fields

| Field        | Type    | allow_nil?                | Status     |
| ------------ | ------- | ------------------------- | ---------- |
| filename     | string  | false                     | ✅ Correct |
| size         | integer | false                     | ✅ Correct |
| url          | string  | false                     | ✅ Correct |
| content_type | string  | true (optional)           | ✅ Correct |
| height       | integer | true (optional, nullable) | ✅ Correct |
| width        | integer | true (optional, nullable) | ✅ Correct |

### ❌ Incorrect Fields

#### 1. `id` - Incorrect Type

**Current:**

```elixir
field :id, :integer, allow_nil?: false, description: "Attachment id"
```

**Discord API Specification:**

- Type: `string` (not integer)
- Required: Yes

**Recommended Fix:**

```elixir
field :id, :string, allow_nil?: false, description: "Attachment id"
```

#### 2. `proxy_url` - Incorrect allow_nil? Setting

**Current:**

```elixir
field :proxy_url, :string, description: "Proxy url of the file"
```

- Currently allows nil (default is `allow_nil?: true`)
- Missing explicit `allow_nil?: false`

**Discord API Specification:**

- Type: `string`
- Required: Yes (not optional)

**Recommended Fix:**

```elixir
field :proxy_url, :string, allow_nil?: false, description: "A proxied url of file"
```

### ⚠️ Missing Fields from Discord API

The following fields exist in the Discord API Attachment Object but are missing
from our implementation:

#### 1. `description` (Optional)

**Discord API Specification:**

- Type: `string`
- Optional: Yes
- Description: "Description for the file"

**Recommended Addition:**

```elixir
field :description, :string, allow_nil?: true, description: "Description for the file (optional)"
```

#### 2. `title` (Optional)

**Discord API Specification:**

- Type: `string`
- Optional: Yes
- Description: "The title of the file"

**Recommended Addition:**

```elixir
field :title, :string, allow_nil?: true, description: "The title of the file (optional)"
```

#### 3. `ephemeral` (Optional)

**Discord API Specification:**

- Type: `boolean`
- Optional: Yes
- Description: "Whether this attachment is ephemeral"

**Recommended Addition:**

```elixir
field :ephemeral, :boolean, allow_nil?: true, description: "Whether this attachment is ephemeral (optional)"
```

#### 4. `duration_secs` (Optional)

**Discord API Specification:**

- Type: `number`
- Optional: Yes
- Description: "The duration of the audio file (currently for voice messages)"

**Recommended Addition:**

```elixir
field :duration_secs, :float, allow_nil?: true, description: "The duration of the audio file in seconds, currently for voice messages (optional)"
```

#### 5. `waveform` (Optional)

**Discord API Specification:**

- Type: `string`
- Optional: Yes
- Description: "Base64 encoded bytearray representing a sampled waveform"

**Recommended Addition:**

```elixir
field :waveform, :string, allow_nil?: true, description: "Base64 encoded bytearray representing a sampled waveform (optional)"
```

#### 6. `flags` (Optional)

**Discord API Specification:**

- Type: `AttachmentFlags` (integer bitfield)
- Optional: Yes
- Description: "Attachment flags combined as a bitfield"

**Recommended Addition:**

```elixir
field :flags, :integer, allow_nil?: true, description: "Attachment flags combined as a bitfield (optional)"
```

### 📝 Extra Fields Not in Discord API

No extra fields found - all current fields exist in Discord API.

---

## Complete Corrected TypedStruct

Here is the complete corrected version of the typed_struct block with all fields
properly defined:

```elixir
typed_struct do
  # Required fields
  field :id, :string, allow_nil?: false, description: "Attachment id"
  field :filename, :string, allow_nil?: false, description: "Name of file attached"
  field :size, :integer, allow_nil?: false, description: "Size of file in bytes"
  field :url, :string, allow_nil?: false, description: "Source url of file"
  field :proxy_url, :string, allow_nil?: false, description: "A proxied url of file"

  # Optional fields - dimensions (nullable)
  field :height, :integer, allow_nil?: true, description: "Height of file, if image (optional, nullable)"
  field :width, :integer, allow_nil?: true, description: "Width of file, if image (optional, nullable)"

  # Optional fields - metadata
  field :content_type, :string, allow_nil?: true, description: "The attachment's media type (optional)"
  field :description, :string, allow_nil?: true, description: "Description for the file (optional)"
  field :title, :string, allow_nil?: true, description: "The title of the file (optional)"
  field :ephemeral, :boolean, allow_nil?: true, description: "Whether this attachment is ephemeral (optional)"

  # Optional fields - audio/voice
  field :duration_secs, :float, allow_nil?: true, description: "The duration of the audio file in seconds, currently for voice messages (optional)"
  field :waveform, :string, allow_nil?: true, description: "Base64 encoded bytearray representing a sampled waveform (optional)"

  # Optional fields - flags
  field :flags, :integer, allow_nil?: true, description: "Attachment flags combined as a bitfield (optional)"
end
```

---

## Action Items

1. **Critical Fix:** Change `id` field type from `:integer` to `:string`
2. **Critical Fix:** Add `allow_nil?: false` to `proxy_url` field
3. **Enhancement:** Add `description` field (optional string)
4. **Enhancement:** Add `title` field (optional string)
5. **Enhancement:** Add `ephemeral` field (optional boolean)
6. **Enhancement:** Add `duration_secs` field (optional float for voice
   messages)
7. **Enhancement:** Add `waveform` field (optional string for audio waveform
   data)
8. **Enhancement:** Add `flags` field (optional integer bitfield)

---

## Notes

- **ID Type Change:** Discord API uses string IDs (snowflakes) for attachments,
  not integers. This is a critical breaking change.
- **New Audio Features:** Discord has added voice message support with
  `duration_secs` and `waveform` fields
- **Ephemeral Attachments:** New `ephemeral` field indicates temporary
  attachments
- **Title and Description:** Allow richer metadata for attachments
- **Flags:** Bitfield for attachment-specific flags (following Discord's pattern
  of using flags for feature toggles)

All optional fields should have `allow_nil?: true` to properly handle cases
where Discord doesn't include them in the payload.
