# Channel Payload Verification Report

**Date:** 2025-10-05 **File:**
`/home/joba/sandbox/ash_discord/lib/ash_discord/consumer/payloads/channel.ex`
**Reference:**
[Discord API - Channel Object](https://discord.com/developers/docs/resources/channel#channel-object)

## Summary

This report compares the AshDiscord Channel payload TypedStruct against the
official Discord API Channel Object structure (current as of 2025).

## Legend

- ✅ **Correct**: Field matches Discord API specification
- ⚠️ **Needs Correction**: Field exists but has incorrect configuration
- ❌ **Missing**: Field exists in Discord API but not in our payload
- 🔍 **Extra**: Field exists in our payload but not in Discord API
- 📝 **Note**: Additional information or context

## Detailed Field Analysis

### ✅ Correct Fields

1. **id** - ✅ Correct

   - Type: `:integer` (snowflake) ✓
   - `allow_nil?: false` ✓
   - Discord API: Required, non-nullable

2. **type** - ✅ Correct

   - Type: `:integer` ✓
   - `allow_nil?: false` ✓
   - Discord API: Required, non-nullable

3. **applied_tags** - ✅ Correct
   - Type: `{:array, :integer}` ✓
   - `allow_nil?: true` (implicit) ✓
   - Discord API: Optional field (`applied_tags?`), array of snowflakes

### ⚠️ Fields Needing Corrections

4. **guild_id** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :guild_id, :integer`
   - Discord API: `guild_id?` (optional field)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

5. **position** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :position, :integer`
   - Discord API: `position?` (optional field)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

6. **permission_overwrites** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :permission_overwrites, {:array, :map}`
   - Discord API: `permission_overwrites?` (optional field)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

7. **name** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :name, :string`
   - Discord API: `name? ?string` (optional AND nullable)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

8. **topic** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :topic, :string`
   - Discord API: `topic? ?string` (optional AND nullable)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

9. **last_message_id** - ⚠️ Needs explicit `allow_nil?: true`

   - Current: `field :last_message_id, :integer`
   - Discord API: `last_message_id? ?snowflake` (optional AND nullable)
   - **Issue**: Missing explicit `allow_nil?: true`
   - **Fix**: Add `allow_nil?: true`

10. **bitrate** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :bitrate, :integer`
    - Discord API: `bitrate?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

11. **user_limit** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :user_limit, :integer`
    - Discord API: `user_limit?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

12. **rate_limit_per_user** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :rate_limit_per_user, :integer`
    - Discord API: `rate_limit_per_user?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

13. **recipients** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :recipients, {:array, :map}`
    - Discord API: `recipients?` (optional field, array of user objects)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

14. **icon** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :icon, :string`
    - Discord API: `icon? ?string` (optional AND nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

15. **owner_id** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :owner_id, :integer`
    - Discord API: `owner_id?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

16. **application_id** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :application_id, :integer`
    - Discord API: `application_id?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

17. **parent_id** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :parent_id, :integer`
    - Discord API: `parent_id? ?snowflake` (optional AND nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

18. **last_pin_timestamp** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :last_pin_timestamp, :utc_datetime`
    - Discord API: `last_pin_timestamp? ?ISO8601 timestamp` (optional AND
      nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

19. **rtc_region** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :rtc_region, :string`
    - Discord API: `rtc_region? ?string` (optional AND nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

20. **video_quality_mode** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :video_quality_mode, :integer`
    - Discord API: `video_quality_mode?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

21. **message_count** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :message_count, :integer`
    - Discord API: `message_count?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

22. **member_count** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :member_count, :integer`
    - Discord API: `member_count?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

23. **thread_metadata** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :thread_metadata, :map`
    - Discord API: `thread_metadata?` (optional field, thread metadata object)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

24. **member** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :member, :map`
    - Discord API: `member?` (optional field, thread member object)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

25. **default_auto_archive_duration** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :default_auto_archive_duration, :integer`
    - Discord API: `default_auto_archive_duration?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

26. **permissions** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :permissions, :string`
    - Discord API: `permissions?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

27. **available_tags** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :available_tags, {:array, :map}`
    - Discord API: `available_tags?` (optional field, array of tag objects)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

28. **default_reaction_emoji** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :default_reaction_emoji, :map`
    - Discord API: `default_reaction_emoji? ?default reaction object` (optional
      AND nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

29. **default_thread_rate_limit_per_user** - ⚠️ Needs explicit
    `allow_nil?: true`

    - Current: `field :default_thread_rate_limit_per_user, :integer`
    - Discord API: `default_thread_rate_limit_per_user?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

30. **default_sort_order** - ⚠️ Needs explicit `allow_nil?: true`

    - Current: `field :default_sort_order, :integer`
    - Discord API: `default_sort_order? ?integer` (optional AND nullable)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

31. **default_forum_layout** - ⚠️ Needs explicit `allow_nil?: true`
    - Current: `field :default_forum_layout, :integer`
    - Discord API: `default_forum_layout?` (optional field)
    - **Issue**: Missing explicit `allow_nil?: true`
    - **Fix**: Add `allow_nil?: true`

### ❌ Missing Fields from Discord API

32. **nsfw** - ❌ Missing

    - Discord API: `nsfw?` (optional field, boolean)
    - Description: "whether the channel is nsfw"
    - **Recommendation**: Add this field

33. **managed** - ❌ Missing

    - Discord API: `managed?` (optional field, boolean)
    - Description: "for group DM channels: whether the channel is managed by an
      application via the `gdm.join` OAuth2 scope"
    - **Recommendation**: Add this field

34. **flags** - ❌ Missing

    - Discord API: `flags?` (optional field, integer)
    - Description: "channel flags combined as a bitfield"
    - **Recommendation**: Add this field

35. **total_message_sent** - ❌ Missing
    - Discord API: `total_message_sent?` (optional field, integer)
    - Description: "number of messages ever sent in a thread, it's similar to
      `message_count` on message creation, but will not decrement the number
      when a message is deleted"
    - **Recommendation**: Add this field

### 🔍 Extra Fields Not in Discord API

36. **newly_created** - 🔍 Extra field
    - Current: `field :newly_created, :boolean`
    - **Status**: Not found in current Discord API Channel Object documentation
    - **Note**: This may be a Nostrum-specific field or deprecated Discord field
    - **Recommendation**: Verify if this is needed for Nostrum compatibility or
      can be removed

## Recommended Changes

### Update existing fields to add `allow_nil?: true`

All optional fields (marked with `?` in Discord API) should explicitly set
`allow_nil?: true`:

```elixir
# Lines 17-18: Already optional in Discord API
field :guild_id, :integer, allow_nil?: true,
  description: "The id of the guild the channel is located in"

field :position, :integer, allow_nil?: true,
  description: "Sorting position of the channel"

# Line 20-21: Already optional in Discord API
field :permission_overwrites, {:array, :map}, allow_nil?: true,
  description: "Permission overwrites for members and roles"

# Line 23: Optional AND nullable in Discord API
field :name, :string, allow_nil?: true,
  description: "The name of the channel"

# Line 24: Optional AND nullable in Discord API
field :topic, :string, allow_nil?: true,
  description: "The channel topic"

# Line 27-28: Optional AND nullable in Discord API
field :last_message_id, :integer, allow_nil?: true,
  description: "The id of the last message sent in this channel"

# Line 30: Already optional in Discord API
field :bitrate, :integer, allow_nil?: true,
  description: "The bitrate (in bits) of the voice channel"

# Line 31: Already optional in Discord API
field :user_limit, :integer, allow_nil?: true,
  description: "The user limit of the voice channel"

# Line 33-34: Already optional in Discord API
field :rate_limit_per_user, :integer, allow_nil?: true,
  description: "Amount of seconds a user has to wait before sending another message"

# Line 36: Already optional in Discord API
field :recipients, {:array, :map}, allow_nil?: true,
  description: "The recipients of the DM"

# Line 37: Optional AND nullable in Discord API
field :icon, :string, allow_nil?: true,
  description: "Icon hash"

# Line 38: Already optional in Discord API
field :owner_id, :integer, allow_nil?: true,
  description: "Id of the DM creator"

# Line 40-41: Already optional in Discord API
field :application_id, :integer, allow_nil?: true,
  description: "Application id of the group DM creator if it is bot-created"

# Line 43: Optional AND nullable in Discord API
field :parent_id, :integer, allow_nil?: true,
  description: "Id of the parent category for a channel"

# Line 45-46: Optional AND nullable in Discord API
field :last_pin_timestamp, :utc_datetime, allow_nil?: true,
  description: "When the last pinned message was pinned"

# Line 48: Optional AND nullable in Discord API
field :rtc_region, :string, allow_nil?: true,
  description: "Voice region id for the voice channel"

# Line 50-51: Already optional in Discord API
field :video_quality_mode, :integer, allow_nil?: true,
  description: "The camera video quality mode of the voice channel"

# Line 53: Already optional in Discord API
field :message_count, :integer, allow_nil?: true,
  description: "Approximate count of messages in a thread"

# Line 54: Already optional in Discord API
field :member_count, :integer, allow_nil?: true,
  description: "Approximate count of users in a thread"

# Line 55: Already optional in Discord API
field :thread_metadata, :map, allow_nil?: true,
  description: "Thread-specific fields"

# Line 56: Already optional in Discord API
field :member, :map, allow_nil?: true,
  description: "Thread member object for the current user"

# Line 58-59: Already optional in Discord API
field :default_auto_archive_duration, :integer, allow_nil?: true,
  description: "Default duration for newly created threads"

# Line 61-62: Already optional in Discord API
field :permissions, :string, allow_nil?: true,
  description: "Computed permissions for the invoking user in the channel"

# Line 66-67: Already optional in Discord API
field :available_tags, {:array, :map}, allow_nil?: true,
  description: "Set of tags that can be used in a forum channel"

# Line 73-74: Optional AND nullable in Discord API
field :default_reaction_emoji, :map, allow_nil?: true,
  description: "The emoji to show in the add reaction button on a thread in a forum channel"

# Line 76-77: Already optional in Discord API
field :default_thread_rate_limit_per_user, :integer, allow_nil?: true,
  description: "The initial rate_limit_per_user to set on newly created threads in a channel"

# Line 79-80: Optional AND nullable in Discord API
field :default_sort_order, :integer, allow_nil?: true,
  description: "The default sort order type used to order posts in a forum channel"

# Line 82-83: Already optional in Discord API
field :default_forum_layout, :integer, allow_nil?: true,
  description: "The default forum layout view used to display posts in a forum channel"
```

### Add missing fields from Discord API

```elixir
# Add after line 24 (after topic field)
field :nsfw, :boolean, allow_nil?: true,
  description: "Whether the channel is NSFW"

# Add after line 41 (after application_id field)
field :managed, :boolean, allow_nil?: true,
  description: "For group DM channels: whether the channel is managed by an application via the gdm.join OAuth2 scope"

# Add after line 62 (after permissions field)
field :flags, :integer, allow_nil?: true,
  description: "Channel flags combined as a bitfield"

# Add after line 53 (after message_count field)
field :total_message_sent, :integer, allow_nil?: true,
  description: "Number of messages ever sent in a thread, similar to message_count but does not decrement when messages are deleted"
```

### Review extra field

```elixir
# Line 64: Not in current Discord API docs
# Consider removing or documenting why this Nostrum-specific field is needed
field :newly_created, :boolean, description: "Whether the thread is newly created"
```

## Statistics

- **Total fields in Discord API**: 36
- **Total fields in current implementation**: 33
- **Correct fields**: 3
- **Fields needing `allow_nil?: true`**: 28
- **Missing fields**: 4
- **Extra fields**: 1

## Priority Recommendations

### High Priority

1. Add `allow_nil?: true` to all 28 optional fields (prevents runtime errors
   when Discord omits fields)
2. Add the 4 missing fields: `nsfw`, `managed`, `flags`, `total_message_sent`

### Medium Priority

1. Investigate `newly_created` field - verify if Nostrum-specific or can be
   removed

### Low Priority

1. Update field descriptions to match Discord API documentation more closely
2. Add notes about nullable vs optional distinctions in comments

## Notes on Discord API Conventions

From the Discord API documentation:

- **Field marked with `?` at end** (e.g., `field?`) → Optional field, may be
  omitted entirely
- **Field marked with `?` before type** (e.g., `?string`) → Nullable field, may
  be `null`
- **Field marked with both** (e.g., `field? ?string`) → Both optional AND
  nullable
- **No marking** → Required and non-nullable field

In Elixir TypedStruct:

- Optional or nullable fields should use `allow_nil?: true`
- Only truly required non-nullable fields should omit `allow_nil?` or set it to
  `false`

## Conclusion

The Channel payload needs 28 fields updated to add explicit `allow_nil?: true`,
plus 4 new fields added to match the current Discord API specification. The
changes are straightforward and primarily involve making optional fields
explicitly nullable to match Discord's API behavior.
