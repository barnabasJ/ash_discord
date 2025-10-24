Generic Handler Implementation Workflow

Implement the [$ARGUMENTS] event handler group. Look for the event names in
`lib/ash_discord/consumer/event_map.ex` to find the handler module paths and
function names.

Follow this systematic approach:

1. **Check event_map.ex** - Verify the handler module path and function names
   for these events

2. **Verify/Create Payload TypedStructs** - Ensure we have payload modules for
   all events in `lib/ash_discord/consumer/payloads/`:

   - First, check the Nostrum struct definition in
     `deps/nostrum/lib/nostrum/struct/` to understand the data structure
   - Review any nested structs referenced in the Nostrum struct
   - Create TypedStruct modules that mirror the Nostrum structure, converting to
     our naming conventions
   - Implement `new/1` function to transform Nostrum struct to our TypedStruct

3. **Create/Update Handler Module** - Implement the handler at the path
   specified in event_map.ex:

   - Use 3-parameter signature: `def function_name(payload, ws_state, context)`
   - For CREATE/UPDATE events: Use
     `Ash.Changeset.for_create(:from_discord, %{data: payload})`
   - For DELETE events: Use `Ash.Query.filter()` and `Ash.bulk_destroy()`
   - Always set ash_discord context flags
   - Return `:ok` on success or `{:error, reason}` on failure

4. **Create/Update FromDiscord Change** (for CREATE/UPDATE events):

   - Create change module in `lib/ash_discord/changes/from_discord/`
   - Implement `change/2` to transform payload data to resource attributes
   - Handle any API fallback needs
   - Note: DELETE events use default :destroy action, no change needed

5. **Create/Update Test Resource** (ALWAYS - for every event):

   - Create resource in `test/support/test_app/discord/`
   - Define attributes matching Discord API fields
   - **CRITICAL**: Follow Discord ID naming convention:
     - All Discord-sourced IDs must use `*_discord_id` naming (e.g.,
       `user_discord_id`, `guild_discord_id`, `owner_discord_id`)
     - Never use bare names like `user_id`, `guild_id` for Discord IDs
     - See CLAUDE.md project instructions for this requirement
   - **Relationships**: For non-polymorphic Discord ID references:
     - Create `belongs_to` relationships with `source_attribute: :*_discord_id`
       and `destination_attribute: :discord_id`
     - Add `attribute_writable?(true)` to allow direct ID setting
     - Example:
       `belongs_to :user, TestApp.Discord.User do source_attribute(:user_discord_id); destination_attribute(:discord_id); attribute_writable?(true) end`
   - **Polymorphic Fields**: Fields that can reference multiple entity types
     (like audit log `target_discord_id`) should be attributes only, NO
     relationships
   - Create `:from_discord` action with data argument and change (for
     CREATE/UPDATE)
   - Set up upsert with `:discord_id` identity
   - Use default `:destroy` action for deletes
   - **Purpose**: Even for informational events, the test resource serves as a
     trace to verify the handler executed correctly. In real applications, users
     can attach their own side effects to these actions.

6. **Verify Integration** - Test that events flow correctly through the system

Follow existing patterns from Channel, Role, and GuildMember handlers.

Before starting, ensure you understand the overall architecture:

- `lib/ash_discord/consumer/handler.ex` - Main handler module routing events
- `lib/ash_discord/consumer/event_map.ex` - Maps events to handler modules
- `lib/ash_discord/consumer/payloads/` - TypedStructs for event payloads
- `lib/ash_discord/changes/from_discord/` - Changes for processing payloads
- `test/support/test_app/discord/` - Test resources for verifying handlers
- `test/ash_discord/consumer/handler/` - Tests for each handler module
- `test/ash_discord/changes/from_discord` - Tests for change modules

This workflow ensures a consistent and reliable implementation of event handlers
across the AshDiscord library.

Before implementing, review existing handlers for reference and consistency.
Check what is currently implemented to avoid duplication. Make a list of all the
events you need to handle for this group. And all the setps that need to be done
for each event. Go into detail and tell the user if a step is already
implemented if an event might only need a subset of the steps done. or if maybe
one event is already implemented. And present detail findings with links so it
is easy to verify your findings.

Make sure to follow the steps in order for a smooth implementation process.
