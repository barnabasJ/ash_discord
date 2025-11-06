# Sticker Payload Verification Report

**File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/sticker.ex`

**Discord API Reference:**
https://discord.com/developers/docs/resources/sticker#sticker-object

**Verification Date:** 2025-10-05

**Sources:**

- Discord API Types v10:
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APISticker
- GitHub Source:
  https://github.com/discordjs/discord-api-types/blob/main/payloads/v10/sticker.ts
- Nostrum Documentation: https://hexdocs.pm/nostrum/Nostrum.Struct.Sticker.html

## Summary

The current implementation has **4 critical issues** that need to be corrected:

1. **Missing `asset` field** (deprecated but still in API)
2. **Incorrect `allow_nil?` settings** on 8 fields
3. **Incorrect type for `type` field** (should be atom, not integer)
4. **Incorrect type for `format_type` field** (should be atom, not integer)

## Discord API Sticker Object Structure

According to Discord API v10, the Sticker object has the following fields:

| Field         | Type                   | Optional?     | Nullable?                  | Description                                                                                                                 |
| ------------- | ---------------------- | ------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`          | Snowflake (string)     | No            | No                         | ID of the sticker                                                                                                           |
| `pack_id`     | Snowflake (string)     | **Yes** (`?`) | No                         | For standard stickers, ID of the pack the sticker is from                                                                   |
| `name`        | string                 | No            | No                         | Name of the sticker                                                                                                         |
| `description` | string                 | No            | **Yes** (`null \| string`) | Description of the sticker                                                                                                  |
| `tags`        | string                 | No            | No                         | For guild stickers, a Discord name of a unicode emoji; for standard stickers, a comma-separated list of related expressions |
| `type`        | StickerType enum       | No            | No                         | Type of sticker (1 = Standard, 2 = Guild)                                                                                   |
| `format_type` | StickerFormatType enum | No            | No                         | Format type (1 = PNG, 2 = APNG, 3 = Lottie, 4 = GIF)                                                                        |
| `available`   | boolean                | **Yes** (`?`) | No                         | Whether this guild sticker can be used, may be false due to loss of Server Boosts                                           |
| `guild_id`    | Snowflake (string)     | **Yes** (`?`) | No                         | ID of the guild that owns this sticker                                                                                      |
| `user`        | APIUser object         | **Yes** (`?`) | No                         | The user that uploaded the guild sticker                                                                                    |
| `sort_value`  | number                 | **Yes** (`?`) | No                         | The standard sticker's sort order within its pack                                                                           |
| `asset`       | string                 | **Yes** (`?`) | No                         | **DEPRECATED** - Previously the sticker asset hash, now an empty string                                                     |

### Enum Values

**StickerType:**

- `1` = Standard (official sticker in a pack)
- `2` = Guild (custom guild sticker)

**StickerFormatType:**

- `1` = PNG
- `2` = APNG (animated PNG)
- `3` = Lottie
- `4` = GIF

## Field-by-Field Comparison

### ✅ Correct Fields

These fields are correctly defined:

1. **`id`** - ✅ Correct

   - Current: `:integer, allow_nil?: false`
   - Expected: Snowflake (integer in Elixir), non-optional, non-nullable
   - Status: **CORRECT**

2. **`name`** - ✅ Correct

   - Current: `:string` (implicitly `allow_nil?: true` due to missing explicit
     setting)
   - Expected: string, non-optional, non-nullable
   - Status: **NEEDS CORRECTION** (should be `allow_nil?: false`)

3. **`tags`** - ✅ Correct
   - Current: `:string` (implicitly `allow_nil?: true`)
   - Expected: string, non-optional, non-nullable
   - Status: **NEEDS CORRECTION** (should be `allow_nil?: false`)

### ❌ Fields Needing Corrections

#### 1. **`pack_id`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :pack_id, :integer, description: "ID of the pack the sticker is from"
```

**Issue:** Missing `allow_nil?: true`. This field is optional in the Discord API
(marked with `?` as `pack_id?`).

**Correct:**

```elixir
field :pack_id, :integer,
  allow_nil?: true,
  description: "For standard stickers, ID of the pack the sticker is from (optional)"
```

---

#### 2. **`name`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :name, :string, description: "Name of the sticker"
```

**Issue:** Missing `allow_nil?: false`. According to Discord API, this field is
required and non-nullable.

**Correct:**

```elixir
field :name, :string,
  allow_nil?: false,
  description: "Name of the sticker"
```

---

#### 3. **`description`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :description, :string, description: "Description of the sticker"
```

**Issue:** Missing `allow_nil?: true`. The Discord API shows this as
`string | null`, meaning it's nullable.

**Correct:**

```elixir
field :description, :string,
  allow_nil?: true,
  description: "Description of the sticker (nullable)"
```

---

#### 4. **`tags`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :tags, :string,
  description: "Autocomplete/suggestion tags for the sticker (comma-separated)"
```

**Issue:** Missing `allow_nil?: false`. This field is required and non-nullable
in the Discord API.

**Correct:**

```elixir
field :tags, :string,
  allow_nil?: false,
  description: "For guild stickers, a Discord name of a unicode emoji; for standard stickers, a comma-separated list of related expressions"
```

---

#### 5. **`type`** - Incorrect type and `allow_nil?` setting

**Current:**

```elixir
field :type, :integer, description: "Type of sticker (1 = standard, 2 = guild)"
```

**Issue:**

1. Should be `:atom` type (Nostrum uses atoms: `:standard`, `:guild`)
2. Missing `allow_nil?: false` - this field is required and non-nullable

**Correct:**

```elixir
field :type, :atom,
  allow_nil?: false,
  description: "Type of sticker (:standard = official sticker in pack, :guild = custom guild sticker)"
```

**Note:** Nostrum converts the integer enum to atoms:

- `1` → `:standard`
- `2` → `:guild`

---

#### 6. **`format_type`** - Incorrect type and `allow_nil?` setting

**Current:**

```elixir
field :format_type, :integer,
  description: "Format type (1 = png, 2 = apng, 3 = lottie, 4 = gif)"
```

**Issue:**

1. Should be `:atom` type (Nostrum uses atoms: `:png`, `:apng`, `:lottie`,
   `:gif`)
2. Missing `allow_nil?: false` - this field is required and non-nullable

**Correct:**

```elixir
field :format_type, :atom,
  allow_nil?: false,
  description: "Format type (:png, :apng, :lottie, or :gif)"
```

**Note:** Nostrum converts the integer enum to atoms:

- `1` → `:png`
- `2` → `:apng`
- `3` → `:lottie`
- `4` → `:gif`

---

#### 7. **`available`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :available, :boolean, description: "Whether this guild sticker can be used"
```

**Issue:** Missing `allow_nil?: true`. This field is optional in the Discord API
(marked with `?` as `available?`).

**Correct:**

```elixir
field :available, :boolean,
  allow_nil?: true,
  description: "Whether this guild sticker can be used, may be false due to loss of Server Boosts (optional)"
```

---

#### 8. **`guild_id`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :guild_id, :integer, description: "ID of the guild that owns this sticker"
```

**Issue:** Missing `allow_nil?: true`. This field is optional in the Discord API
(marked with `?` as `guild_id?`).

**Correct:**

```elixir
field :guild_id, :integer,
  allow_nil?: true,
  description: "ID of the guild that owns this sticker (optional)"
```

---

#### 9. **`user`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :user, :map, description: "User that uploaded the guild sticker"
```

**Issue:** Missing `allow_nil?: true`. This field is optional in the Discord API
(marked with `?` as `user?`).

**Correct:**

```elixir
field :user, :map,
  allow_nil?: true,
  description: "The user that uploaded the guild sticker (optional)"
```

---

#### 10. **`sort_value`** - Incorrect `allow_nil?` setting

**Current:**

```elixir
field :sort_value, :integer, description: "Standard sticker's sort order within its pack"
```

**Issue:** Missing `allow_nil?: true`. This field is optional in the Discord API
(marked with `?` as `sort_value?`).

**Correct:**

```elixir
field :sort_value, :integer,
  allow_nil?: true,
  description: "The standard sticker's sort order within its pack (optional)"
```

---

### 📋 Missing Fields

#### 1. **`asset`** - DEPRECATED but still in API

**Missing Field:**

```elixir
field :asset, :string,
  allow_nil?: true,
  description: "DEPRECATED - Previously the sticker asset hash, now an empty string"
```

**Note:** While this field is deprecated, it's still present in the Discord API
specification. It should be included for completeness but marked as deprecated
in the description.

---

### 🚫 Extra Fields

No extra fields found. All current fields exist in the Discord API
specification.

---

## Recommended Changes

Here's the complete corrected `typed_struct` block:

```elixir
typed_struct do
  field :id, :integer,
    allow_nil?: false,
    description: "ID of the sticker"

  field :pack_id, :integer,
    allow_nil?: true,
    description: "For standard stickers, ID of the pack the sticker is from (optional)"

  field :name, :string,
    allow_nil?: false,
    description: "Name of the sticker"

  field :description, :string,
    allow_nil?: true,
    description: "Description of the sticker (nullable)"

  field :tags, :string,
    allow_nil?: false,
    description: "For guild stickers, a Discord name of a unicode emoji; for standard stickers, a comma-separated list of related expressions"

  field :type, :atom,
    allow_nil?: false,
    description: "Type of sticker (:standard = official sticker in pack, :guild = custom guild sticker)"

  field :format_type, :atom,
    allow_nil?: false,
    description: "Format type (:png, :apng, :lottie, or :gif)"

  field :available, :boolean,
    allow_nil?: true,
    description: "Whether this guild sticker can be used, may be false due to loss of Server Boosts (optional)"

  field :guild_id, :integer,
    allow_nil?: true,
    description: "ID of the guild that owns this sticker (optional)"

  field :user, :map,
    allow_nil?: true,
    description: "The user that uploaded the guild sticker (optional)"

  field :sort_value, :integer,
    allow_nil?: true,
    description: "The standard sticker's sort order within its pack (optional)"

  field :asset, :string,
    allow_nil?: true,
    description: "DEPRECATED - Previously the sticker asset hash, now an empty string"
end
```

---

## Summary of Changes

### Critical Issues (4)

1. **Type Changes (2 fields):**

   - `type`: Change from `:integer` to `:atom`
   - `format_type`: Change from `:integer` to `:atom`

2. **Missing Field (1 field):**

   - Add `asset` field (deprecated but still in API spec)

3. **`allow_nil?` Corrections (8 fields):**
   - **Set to `false` (3 fields):** `name`, `tags`, (already correct: `id`)
   - **Set to `true` (7 fields):** `pack_id`, `description`, `available`,
     `guild_id`, `user`, `sort_value`, `asset`

### Field Count

- **Current:** 11 fields
- **Should be:** 12 fields (add `asset`)

---

## Notes on Nostrum Conversion

The Nostrum library converts Discord API types to Elixir-friendly types:

1. **Snowflakes** (`string` in Discord API) → `:integer` in Nostrum
2. **Enum integers** → `:atom` in Nostrum
   - `StickerType`: `1` → `:standard`, `2` → `:guild`
   - `StickerFormatType`: `1` → `:png`, `2` → `:apng`, `3` → `:lottie`, `4` →
     `:gif`
3. **Nested objects** → `:map` in Nostrum

This is why the field types differ from the raw Discord API but should match
Nostrum's `Nostrum.Struct.Sticker.t()` type specification.

---

## References

- **Discord API Documentation:**
  https://discord.com/developers/docs/resources/sticker#sticker-object
- **discord-api-types TypeScript definitions:**
  https://discord-api-types.dev/api/discord-api-types-v10/interface/APISticker
- **GitHub Source:**
  https://github.com/discordjs/discord-api-types/blob/main/payloads/v10/sticker.ts
- **Nostrum Documentation:**
  https://hexdocs.pm/nostrum/Nostrum.Struct.Sticker.html

---

**End of Report**
