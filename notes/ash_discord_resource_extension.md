# AshDiscord.Resource Extension - Hybrid Event Mapping with Auto-Discovery

## Architecture Overview

Create a flexible Ash resource extension where:

1. **Resources self-declare** their Discord event handling via `ash_discord do`
   block
2. **Consumer auto-discovers** all resources from configured domains
3. **Entity shortcuts** - `discord_entity :message` auto-maps standard CRUD
   events
4. **Explicit event mapping** - `events do` block for custom event-to-action
   mappings
5. **Conflict detection** - Compile-time error if multiple resources handle the
   same event

## DSL Structure

### Resource Configuration

```elixir
# Simple case - entity shortcut
defmodule MyBot.Message do
  use Ash.Resource, extensions: [AshDiscord.Resource]

  ash_discord do
    discord_entity :message  # Auto-maps MESSAGE_CREATE, MESSAGE_UPDATE, MESSAGE_DELETE
  end
end

# Cross-cutting concerns - explicit events
defmodule MyBot.ActivityLogger do
  use Ash.Resource, extensions: [AshDiscord.Resource]

  ash_discord do
    events do
      on :GUILD_CREATE, :log_guild
      on :USER_UPDATE, :log_user
      on :VOICE_STATE_UPDATE, :log_voice
    end
  end
end

# Hybrid - entity defaults + overrides
defmodule MyBot.CustomMessage do
  use Ash.Resource, extensions: [AshDiscord.Resource]

  ash_discord do
    discord_entity :message

    events do
      on :MESSAGE_DELETE, :soft_delete  # Override default
    end
  end
end
```

### Consumer Configuration (SIMPLIFIED)

```elixir
# Before (OLD):
ash_discord_consumer do
  domains [MyBot.Discord]
  message_resource MyBot.Message
  guild_resource MyBot.Guild
  user_resource MyBot.User
  # ... many manual configs
end

# After (NEW):
ash_discord_consumer do
  domains [MyBot.Discord]
  # Resources auto-discovered!
end
```

## Complete Entity Type Mappings

Based on EventMap and handler tests, support these entity types with their
events:

### Standard Entities

- `:message` - MESSAGE_CREATE, MESSAGE_UPDATE, MESSAGE_DELETE,
  MESSAGE_DELETE_BULK
- `:guild` - GUILD_CREATE, GUILD_UPDATE, GUILD_DELETE, GUILD_AVAILABLE,
  GUILD_UNAVAILABLE
- `:channel` - CHANNEL_CREATE, CHANNEL_UPDATE, CHANNEL_DELETE,
  CHANNEL_PINS_UPDATE
- `:user` - USER_UPDATE
- `:role` - GUILD_ROLE_CREATE, GUILD_ROLE_UPDATE, GUILD_ROLE_DELETE
- `:guild_member` - GUILD_MEMBER_ADD, GUILD_MEMBER_UPDATE, GUILD_MEMBER_REMOVE,
  GUILD_MEMBERS_CHUNK
- `:message_reaction` - MESSAGE_REACTION_ADD, MESSAGE_REACTION_REMOVE,
  MESSAGE_REACTION_REMOVE_ALL, MESSAGE_REACTION_REMOVE_EMOJI
- `:voice_state` - VOICE_STATE_UPDATE, VOICE_SERVER_UPDATE, VOICE_READY,
  VOICE_SPEAKING_UPDATE, VOICE_INCOMING_PACKET
- `:invite` - INVITE_CREATE, INVITE_DELETE
- `:interaction` - INTERACTION_CREATE
- `:presence` - PRESENCE_UPDATE
- `:typing_indicator` - TYPING_START

### Thread Entities

- `:thread` - THREAD_CREATE, THREAD_UPDATE, THREAD_DELETE, THREAD_LIST_SYNC
- `:thread_member` - THREAD_MEMBER_UPDATE, THREAD_MEMBERS_UPDATE

### Guild Sub-Entities

- `:guild_ban` - GUILD_BAN_ADD, GUILD_BAN_REMOVE
- `:emoji` - GUILD_EMOJIS_UPDATE
- `:sticker` - GUILD_STICKERS_UPDATE
- `:guild_scheduled_event` - GUILD_SCHEDULED_EVENT_CREATE,
  GUILD_SCHEDULED_EVENT_UPDATE, GUILD_SCHEDULED_EVENT_DELETE,
  GUILD_SCHEDULED_EVENT_USER_ADD, GUILD_SCHEDULED_EVENT_USER_REMOVE
- `:guild_audit_log_entry` - GUILD_AUDIT_LOG_ENTRY_CREATE

### Moderation & Integration

- `:auto_moderation_rule` - AUTO_MODERATION_RULE_CREATE,
  AUTO_MODERATION_RULE_UPDATE, AUTO_MODERATION_RULE_DELETE
- `:auto_moderation_rule_execute` - AUTO_MODERATION_RULE_EXECUTE
- `:integration` - INTEGRATION_CREATE, INTEGRATION_UPDATE, INTEGRATION_DELETE,
  GUILD_INTEGRATIONS_UPDATE
- `:webhooks_update` - WEBHOOKS_UPDATE

### Poll Entities

- `:message_poll_vote` - MESSAGE_POLL_VOTE_ADD, MESSAGE_POLL_VOTE_REMOVE

## Implementation Tasks

### 1. Core Extension Files

**lib/ash_discord/resource.ex**

- Main extension using `Spark.Dsl.Extension`
- Define `@ash_discord` section with nested `@events` section
- Add resource-level transformers
- Specify transformer order

**lib/ash_discord/dsl/resource.ex**

- `discord_entity` optional schema with ALL entity types listed above
- `events` section with `on` entity for explicit event mappings

### 2. Event Entity Definition

**lib/ash_discord/event_mapping.ex**

- Struct to hold event→action mapping
- Used as target for `on` entity

**lib/ash_discord/dsl/resource.ex** - Event entity definition:

```elixir
@event %Spark.Dsl.Entity{
  name: :on,
  target: AshDiscord.EventMapping,
  args: [:event, :action],
  schema: [
    event: [type: :atom, required: true, doc: "Discord event name"],
    action: [type: :atom, required: true, doc: "Ash action to invoke"]
  ]
}

@events %Spark.Dsl.Section{
  name: :events,
  entities: [@event],
  describe: "Explicit Discord event to action mappings"
}
```

### 3. Entity-to-Events Mapper

**lib/ash_discord/resource/entity_events.ex**

- Maps ALL entity types to their Discord events with default actions
- Consult EventMap to ensure complete coverage
- Standard patterns: CREATE→:from_discord, UPDATE→:from_discord, DELETE→:destroy

### 4. Resource-Level Transformers

**lib/ash_discord/resource/transformers/expand_entity_events.ex**

- Priority 1: Expand `discord_entity` to event mappings
- Merge with explicit `events do` (explicit overrides defaults)
- Store final `%{event => action}` map in dsl_state

**lib/ash_discord/resource/transformers/validate_actions.ex**

- Priority 2: Verify all actions exist on resource
- Helpful error messages with available actions listed

**lib/ash_discord/resource/transformers/register_events.ex**

- Priority 3: Persist event mappings for consumer discovery
- Use `Spark.Dsl.Transformer.persist/3`

### 5. Info Module

**lib/ash_discord/resource/info.ex**

- Use `Spark.InfoGenerator`
- Functions: `discord_entity/1`, `discord_events/1`, `discord_event_action/2`

### 6. Resource Discovery

**lib/ash_discord/consumer/resource_discovery.ex**

- `discover_event_handlers/1` - scans domains for AshDiscord.Resource
- Returns: `%{event => {resource, action}}` map
- Returns conflicts: `%{event => [{resource1, action1}, {resource2, action2}]}`

### 7. Consumer-Level Transformer

**lib/ash_discord/consumer/transformers/discover_and_validate_resources.ex**

- Runs during consumer compilation
- Discovers resources from configured domains
- Builds complete event handler map
- **Detects conflicts** - compile-time error if multiple resources handle same
  event
- Persists map to consumer dsl_state for runtime use

### 8. Update Consumer DSL

**lib/ash_discord/dsl/consumer.ex**

- **REMOVE** all resource configuration options (guild_resource,
  message_resource, etc.)
- **KEEP**: `domains`, `store_bot_messages`, `debug_logging`, `command_filter`

### 9. Update Consumer Handler

**lib/ash_discord/consumer/handler.ex**

- Remove `get_resource/2` function
- Add `get_event_handler/2` - looks up {resource, action} from discovered map
- Update `handle_supported_event/8` to use discovered handlers
- Call discovered action on discovered resource

### 10. Update Consumer Info

**lib/ash_discord/consumer/info.ex**

- Add `event_handler/2` - get {resource, action} for event
- Add `all_event_handlers/1` - get complete map

## Default Action Mappings by Entity Type

Standard patterns (exceptions noted):

**CREATE events** → `:from_discord` **UPDATE events** → `:from_discord` **DELETE
events** → `:destroy` **REMOVE events** → `:destroy` **ADD events** →
`:from_discord`

Special cases:

- GUILD_UNAVAILABLE → `:mark_unavailable` or `:from_discord`
- AUTO_MODERATION_RULE_EXECUTE → `:from_discord` (creates execution record)
- WEBHOOKS_UPDATE → `:from_discord` (informational event)
- Message poll votes → ADD→:from_discord, REMOVE→:destroy

## Error Messages

### Conflict Detection

```
** (Spark.Error.DslError) Discord event conflict in MyApp.DiscordConsumer

Multiple resources handle the same Discord event:

  • MESSAGE_CREATE
    - MyApp.Message (via discord_entity :message)
    - MyApp.Logger (via events: on :MESSAGE_CREATE, :log)

Each event can only be handled by one resource.
```

### Missing Action

```
** (Spark.Error.DslError) Invalid action in MyApp.Message

Action :custom_delete does not exist on MyApp.Message

Referenced in: events: on :MESSAGE_DELETE, :custom_delete

Available actions: [:from_discord, :destroy, :read]
```

## Migration Guide

**Breaking Change - User Migration Required**

**Before:**

```elixir
ash_discord_consumer do
  domains [MyBot.Discord]
  message_resource MyBot.Message
  guild_resource MyBot.Guild
end

defmodule MyBot.Message do
  use Ash.Resource
end
```

**After:**

```elixir
ash_discord_consumer do
  domains [MyBot.Discord]
end

defmodule MyBot.Message do
  use Ash.Resource, extensions: [AshDiscord.Resource]

  ash_discord do
    discord_entity :message
  end
end
```

## Benefits

✅ **Simple consumer** - Just specify domains ✅ **Flexible resources** - Entity
shortcuts OR explicit events OR both ✅ **Compile-time safety** - Conflicts
detected during compilation ✅ **Declarative** - Resources self-describe Discord
capabilities ✅ **Maintainable** - No manual resource wiring ✅ **Complete
coverage** - All Discord events from EventMap supported ✅ **Test-verified** -
All entity types from handler tests included

## Implementation Progress

- [ ] 1. Core Extension Files
- [ ] 2. Event Entity Definition
- [ ] 3. Entity-to-Events Mapper
- [ ] 4. Resource-Level Transformers
- [ ] 5. Info Module
- [ ] 6. Resource Discovery
- [ ] 7. Consumer-Level Transformer
- [ ] 8. Update Consumer DSL
- [ ] 9. Update Consumer Handler
- [ ] 10. Update Consumer Info
