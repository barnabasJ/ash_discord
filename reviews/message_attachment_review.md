# MessageAttachment Payload Review

**Review Date:** 2025-10-05 **Payload File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/message_attachment.ex`
**Generator File:**
`/home/joba/sandbox/ash_discord/test/support/generators/discord.ex`
(message_attachment/1) **Verification Report:**
`/home/joba/sandbox/ash_discord/verification_reports/message_attachment_verification.md`

---

## Summary

**Status:** ✅ **CORRECT AND ALIGNED**

The MessageAttachment payload implementation is now correct after recent fixes:

- ✅ `id` type is correctly `:integer` (matches Nostrum's `Snowflake.t()`)
- ✅ `proxy_url` correctly has `allow_nil?: false` (was fixed)
- ✅ `height` and `width` correctly have `allow_nil?: true` (was fixed)
- ✅ Generator correctly handles image vs non-image attachments
- ✅ `content_type` field was correctly REMOVED (not in Nostrum)

The payload correctly implements all fields present in
`Nostrum.Struct.Message.Attachment` with appropriate nullability settings. The
generator produces realistic test data that matches Discord's actual attachment
structure.

---

## Critical Concern Resolution

### 1. ✅ `id` Field Type - CORRECT

**Verification Report Claim:**

> id should be `:string` (Discord API uses string snowflakes)

**Actual Nostrum Implementation:**

```elixir
# From Nostrum.Struct.Message.Attachment
@type id :: Snowflake.t()

# From Nostrum.Snowflake
@type t :: 0..0xFFFFFFFFFFFFFFFF
```

**Current Payload:**

```elixir
field :id, :integer, allow_nil?: false, description: "Attachment id"
```

**Status:** ✅ CORRECT - Nostrum uses **integers** for snowflakes, not strings.
The verification report is incorrect on this point. Discord's API sends
snowflakes as strings in JSON, but Nostrum deserializes them to integers.

**Generator Implementation:**

```elixir
id: generate_snowflake()  # Returns integer
```

✅ Correctly generates integer snowflake IDs

---

### 2. ✅ `proxy_url` Field - CORRECTED

**Nostrum Definition:**

```elixir
@type proxy_url :: String.t()
```

**Current Payload:**

```elixir
field :proxy_url, :string, allow_nil?: false, description: "Proxy url of the file"
```

**Status:** ✅ CORRECTED - Now correctly has `allow_nil?: false` (was fixed as
indicated in the task)

**Generator Implementation:**

```elixir
proxy_url: "https://media.discordapp.net/attachments/#{generate_snowflake()}/#{generate_snowflake()}/#{filename}"
```

✅ Always generates a valid proxy URL

---

### 3. ✅ `height` and `width` Fields - CORRECTED

**Nostrum Definition:**

```elixir
@typedoc "Height of the file (if image)"
@type height :: integer | nil

@typedoc "Width of the file (if image)"
@type width :: integer | nil
```

**Current Payload:**

```elixir
field :height, :integer, allow_nil?: true, description: "Height of the file (if image)"
field :width, :integer, allow_nil?: true, description: "Width of the file (if image)"
```

**Status:** ✅ CORRECTED - Both now correctly have `allow_nil?: true` (was fixed
as indicated in the task)

**Generator Implementation:**

```elixir
height: if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1080), else: nil),
width: if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1920), else: nil)
```

✅ Correctly generates dimensions for images only, `nil` for other file types

---

### 4. ✅ `content_type` Field - CORRECTLY REMOVED

**Nostrum Struct Definition:**

```elixir
defstruct [
  :id,
  :filename,
  :size,
  :url,
  :proxy_url,
  :height,
  :width
]
```

**Status:** ✅ CORRECT - The `content_type` field is **not present** in
Nostrum's Message.Attachment struct, so it was correctly removed from the
payload.

**Note:** The verification report lists `content_type` as a "✅ Correct Field",
but this is based on the Discord API specification. Since we're building
wrappers for **Nostrum structs**, not directly for the Discord API, we correctly
omit fields that Nostrum doesn't include.

---

## Field-by-Field Validation

### Complete Field Comparison

| Field     | Payload Type | allow_nil? | Nostrum Type        | Generator            | Status     |
| --------- | ------------ | ---------- | ------------------- | -------------------- | ---------- |
| id        | :integer     | false      | Snowflake.t() (int) | generate_snowflake() | ✅ Correct |
| filename  | :string      | false      | String.t()          | Realistic filename   | ✅ Correct |
| size      | :integer     | false      | integer             | Random 1KB-8MB       | ✅ Correct |
| url       | :string      | false      | String.t()          | Discord CDN URL      | ✅ Correct |
| proxy_url | :string      | false      | String.t()          | Discord proxy URL    | ✅ Correct |
| height    | :integer     | true       | integer \| nil      | Conditional on image | ✅ Correct |
| width     | :integer     | true       | integer \| nil      | Conditional on image | ✅ Correct |

---

## Generator Quality Assessment

### Strengths

1. **Smart Conditional Logic**: Correctly sets `height` and `width` to `nil` for
   non-image files
2. **Realistic URLs**: Generates proper Discord CDN and proxy URL formats
3. **Varied File Types**: Tests multiple extensions (png, jpg, gif, pdf, txt)
4. **Appropriate File Sizes**: Random sizes from 1KB to 8MB match typical
   attachment ranges
5. **Overridable Attributes**: Allows test-specific customization via `attrs`
   parameter

### Test Coverage

```elixir
# Image file - has dimensions
message_attachment(%{filename: "image.png"})
# => %{height: <integer>, width: <integer>, ...}

# Non-image file - no dimensions
message_attachment(%{filename: "document.pdf"})
# => %{height: nil, width: nil, ...}
```

✅ Generator correctly produces both image and non-image attachment variants

---

## Verification Report Analysis

### Discrepancies with Verification Report

The verification report contains several issues when compared to Nostrum's
actual implementation:

1. **Incorrect ID Type Claim**: Report states `id` should be `:string`, but
   Nostrum uses `:integer`
2. **Missing Fields in Nostrum**: Report lists 7 missing fields (description,
   title, ephemeral, duration_secs, waveform, flags, content_type), but these
   are **not in Nostrum's struct**
3. **Discord API vs Nostrum**: Report compares against Discord API spec, but
   we're wrapping **Nostrum structs**, not raw Discord API

### Correct Approach

Our payload is correctly designed to wrap `Nostrum.Struct.Message.Attachment`,
which includes only these fields:

- `id`, `filename`, `size`, `url`, `proxy_url`, `height`, `width`

If Nostrum doesn't expose additional Discord API fields, we shouldn't add them
to our payload wrapper.

---

## Recommendations

### 1. ✅ No Changes Required to Payload

The current implementation is correct and complete for wrapping
`Nostrum.Struct.Message.Attachment`.

### 2. ✅ No Changes Required to Generator

The generator correctly produces test data matching all Nostrum attachment
fields with appropriate conditional logic.

### 3. 📝 Consider Nostrum Version Tracking

If Discord adds new fields to attachments and Nostrum updates to support them,
we should track Nostrum version updates and add corresponding fields. Current
fields to potentially add in future Nostrum versions:

- `content_type` (MIME type)
- `description` (user-provided description)
- `title` (attachment title)
- `ephemeral` (temporary attachment flag)
- `duration_secs` (for voice messages)
- `waveform` (voice message waveform data)
- `flags` (attachment flags bitfield)

### 4. 📝 Update Verification Report

The verification report should be updated to reflect:

- Nostrum uses integer snowflakes, not strings
- We're wrapping Nostrum structs, not directly implementing Discord API
- Missing fields are expected since Nostrum doesn't expose them

---

## Test Validation Examples

### Example 1: Image Attachment

```elixir
attachment = message_attachment(%{filename: "photo.png"})

assert is_integer(attachment.id)
assert attachment.filename == "photo.png"
assert is_integer(attachment.size)
assert String.contains?(attachment.url, "cdn.discordapp.com")
assert String.contains?(attachment.proxy_url, "media.discordapp.net")
assert is_integer(attachment.height)  # Has dimensions
assert is_integer(attachment.width)   # Has dimensions
```

### Example 2: Document Attachment

```elixir
attachment = message_attachment(%{filename: "document.pdf"})

assert is_integer(attachment.id)
assert attachment.filename == "document.pdf"
assert is_integer(attachment.size)
assert String.contains?(attachment.url, "cdn.discordapp.com")
assert String.contains?(attachment.proxy_url, "media.discordapp.net")
assert attachment.height == nil  # No dimensions
assert attachment.width == nil   # No dimensions
```

### Example 3: Custom Attributes

```elixir
attachment = message_attachment(%{
  id: 123456789,
  filename: "custom.jpg",
  size: 5000,
  height: 1080,
  width: 1920
})

assert attachment.id == 123456789
assert attachment.size == 5000
assert attachment.height == 1080
assert attachment.width == 1920
```

---

## Conclusion

**Overall Assessment:** ✅ **EXCELLENT**

The MessageAttachment payload and generator are correctly implemented and fully
aligned:

1. ✅ All fields match Nostrum's Message.Attachment struct
2. ✅ Field types are correct (including integer snowflakes)
3. ✅ Nullability constraints are correct (proxy_url required, dimensions
   optional)
4. ✅ Generator produces realistic, varied test data
5. ✅ Generator correctly handles image vs non-image conditional logic
6. ✅ `content_type` was correctly removed (not in Nostrum)

**No action items required** - implementation is production-ready.

---

## References

- **Nostrum Source**: `deps/nostrum/lib/nostrum/struct/message/attachment.ex`
- **Nostrum Snowflake**: `deps/nostrum/lib/nostrum/snowflake.ex` (defines
  `Snowflake.t() :: integer`)
- **Discord API**:
  https://discord.com/developers/docs/resources/message#attachment-object
- **Nostrum Docs**:
  https://hexdocs.pm/nostrum/Nostrum.Struct.Message.Attachment.html
