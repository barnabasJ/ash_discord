# Handler Migration Guide: Using `invoke_configured_action`

This guide documents the pattern for migrating Discord event handlers from
manual Ash operation calls to the standardized `invoke_configured_action/4`
function.

EVERY EVENT SHOULD BE MAPPABLE TO AN ASH ACTION

## Table of Contents

1. [Overview](#overview)
2. [Resource Checking - IMPORTANT](#resource-checking---important)
3. [The New Pattern](#the-new-pattern)
4. [Step-by-Step Migration](#step-by-step-migration)
5. [Action Type Patterns](#action-type-patterns)
6. [Common Pitfalls](#common-pitfalls)
7. [Testing Considerations](#testing-considerations)
8. [Complete Example](#complete-example)

## Overview

### What Changed

**Before:** Handlers manually constructed Ash changesets/queries and called Ash
functions directly:

```elixir
context.resource
|> Ash.Changeset.for_create(:from_discord, %{data: guild})
|> Ash.Changeset.set_context(%{
  private: %{ash_discord?: true},
  shared: %{private: %{ash_discord?: true}}
})
|> Ash.create()
```

**After:** Handlers use a standardized function that handles everything:

```elixir
Handler.invoke_configured_action(
  :GUILD_CREATE,
  %{discord_id: guild.id},
  %{identity: guild.id, data: guild},
  context
)
```

Handlers don't need to check if the resource exists, they only get called if
it's there.

### Benefits

- ✅ **Consistent**: All handlers use the same pattern
- ✅ **DRY**: No repeated changeset/query construction
- ✅ **Bulk Operations**: Automatically uses `Ash.bulk_*` for better performance
- ✅ **Context Handling**: Automatically extracts actor/tenant from
  `AshDiscord.Context`
- ✅ **Type Safety**: Single point of action invocation logic
- ✅ **DSL-Driven**: Action names come from resource configuration

## Resource Checking - IMPORTANT

### The Dispatcher Handles Resource Existence

**Critical concept**: Handlers are **only called if a resource is configured**.
You should **never** check for `nil` resources in handler functions.

### How It Works in Production

The event dispatcher (in `AshDiscord.Consumer`) checks for resource existence
**before** calling handlers:

```elixir
# In AshDiscord.Consumer event handling
resource = get_resource(consumer, event)

if resource do
  context = build_context(consumer, resource, transformed_payload)
  # Handler is called here with valid context.resource
  apply(handler_module, handler_function, [consumer, payload, ws_state, context])
else
  # Handler is NOT called - event is silently ignored
  :ok
end
```

This means:

- ✅ Handlers always receive a valid `context.resource` (never `nil`)
- ✅ No need for `case context.resource do nil -> :ok` guards
- ✅ `invoke_configured_action` can safely assume the resource exists

### Old Pattern (❌ DO NOT USE)

```elixir
def create(_consumer, event, _ws_state, context) do
  case context.resource do
    nil ->
      :ok

    resource ->
      # Actually do the work...
      resource
      |> Ash.Changeset.for_create(:from_discord, %{data: event})
      |> Ash.create()
  end
end
```

### New Pattern (✅ USE THIS)

```elixir
def create(_consumer, event, _ws_state, context) do
  # No resource check needed - dispatcher guarantees it exists
  Handler.invoke_configured_action(
    :EVENT_NAME,
    %{discord_id: event.id},
    %{data: event},
    context
  )
end
```

### Testing Implications

When writing tests that call handlers directly, you **must** provide a valid
resource in the context:

```elixir
# ❌ BAD - This will cause invoke_configured_action to crash
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: nil,  # ❌ Don't do this!
  guild: nil,
  user: nil,
  context: %{private: %{ash_discord?: true}}
}

# ✅ GOOD - Provide the actual resource
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: TestApp.Discord.GuildScheduledEvent,  # ✅ Valid resource
  guild: nil,
  user: nil,
  context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
}
```

**Note**: The `context.context` field is also required and should include the
`ash_discord?: true` flag in the private context.

### What About "No Resource Configured" Tests?

**Don't test this in handler tests**. The nil resource scenario is handled by
the dispatcher, not the handler. If you need to test "resource not configured"
behavior:

1. Test it at the **dispatcher level**, not the handler level
2. Or simply trust that the dispatcher works correctly (it's tested elsewhere)

Handler tests should focus on testing the handler's logic when given valid
inputs, which includes a valid `context.resource`.

## The New Pattern

### Function Signature

```elixir
@spec invoke_configured_action(
  event :: atom(),           # Discord event name (e.g., :GUILD_CREATE)
  identity :: term(),        # How to find the record (for update/destroy/read)
  arguments :: map(),        # Data to pass to the action
  context :: AshDiscord.Context.t()
) :: {:ok, any()} | {:error, any()}
```

### How It Works

1. **Looks up action**: Uses
   `AshDiscord.Resource.Info.discord_event_action(resource, event)` to find
   configured action
2. **Determines type**: Checks if action is `:create`, `:update`, `:destroy`,
   `:read`, or `:action`
3. **Builds query** (if needed): For update/destroy/read, builds filter query
   using identity
4. **Invokes operation**: Calls appropriate `Ash.bulk_*` or `Ash.*` function
   with `scope: context`
5. **Formats result**: Returns `{:ok, result}` or `{:error, error}`

### Context Flow

The `context` parameter is passed as `scope: context` to Ash operations, which
triggers the `Ash.Scope.ToOpts` protocol:

```elixir
# AshDiscord.Context implements Ash.Scope.ToOpts
defimpl Ash.Scope.ToOpts do
  def get_actor(%{user: user}) when not is_nil(user), do: {:ok, user}
  def get_tenant(%{guild: guild_id}) when not is_nil(guild_id), do: {:ok, guild_id}
  def get_context(%{context: context}) when not is_nil(context), do: {:ok, context}
  # ...
end
```

This automatically provides:

- **Actor**: From `context.user`
- **Tenant**: From `context.guild`
- **Context metadata**: From `context.context` (includes `ash_discord?: true`)

## Step-by-Step Migration

### Step 1: Identify Handler Functions

Find all functions in your handler that call Ash operations directly:

- `Ash.create/2`
- `Ash.update/2`
- `Ash.destroy/2`
- `Ash.read/2`
- `Ash.run_action/2`

### Step 2: Determine Action Type

For each operation, identify what type of Ash action it's calling:

| Current Code                                    | Action Type         |
| ----------------------------------------------- | ------------------- |
| `Ash.Changeset.for_create` → `Ash.create`       | `:create`           |
| `Ash.Changeset.for_update` → `Ash.update`       | `:update`           |
| `Ash.Changeset.for_destroy` → `Ash.destroy`     | `:destroy`          |
| `Ash.Query.for_read` → `Ash.read`               | `:read`             |
| `Ash.ActionInput.for_action` → `Ash.run_action` | `:action` (generic) |

### Step 3: Extract Event and Identity

**Event**: The Discord event constant (`:GUILD_CREATE`, `:MESSAGE_UPDATE`, etc.)

**Identity**: How to find the record for update/destroy/read operations:

| Identity Format         | Use Case         | Example                                           |
| ----------------------- | ---------------- | ------------------------------------------------- |
| Scalar (integer/string) | Single ID filter | `guild.id` → filters by `id: guild.id`            |
| Map                     | Custom filters   | `%{discord_id: id}` → filters by `discord_id: id` |
| Keyword list            | Multiple filters | `[discord_id: id, channel_id: ch_id]`             |

### Step 4: Prepare Arguments

Arguments are the data passed to the action. Common patterns:

**For `from_discord` actions:**

```elixir
%{
  identity: record_id,  # Often redundant with identity param, but actions may use it
  data: payload         # The Discord payload struct
}
```

**For destroy actions:**

```elixir
%{}  # Usually empty - identity param handles finding the record
```

### Step 5: Handle Return Values

The `invoke_configured_action` returns `{:ok, result}` or `{:error, error}`.

**If your handler spec says it returns `:ok`**, normalize the result:

```elixir
# Before
def update(...) do
  case Ash.create(...) do
    {:ok, _} -> :ok
    {:error, e} -> {:error, e}
  end
end

# After
def update(...) do
  case Handler.invoke_configured_action(...) do
    {:ok, _} -> :ok
    {:error, e} -> {:error, e}
  end
end
```

### Step 6: Remove Manual Context Setting

Delete any manual `Ash.Changeset.set_context` or `Ash.Query.set_context` calls -
the context is now handled automatically via the protocol.

### Step 7: Add Alias (if needed)

Add the handler alias at the top of your module:

```elixir
alias AshDiscord.Consumer.Handler
```

## Action Type Patterns

### Create Actions

**Pattern:**

```elixir
Handler.invoke_configured_action(
  :EVENT_NAME,
  record_id,              # Often the new record's Discord ID
  %{
    identity: record_id,  # May be used by action for idempotency
    data: payload         # The Discord struct/map
  },
  context
)
```

**Before:**

```elixir
context.resource
|> Ash.Changeset.for_create(:from_discord, %{data: guild})
|> Ash.Changeset.set_context(%{
  private: %{ash_discord?: true},
  shared: %{private: %{ash_discord?: true}}
})
|> Ash.create()
```

**After:**

```elixir
Handler.invoke_configured_action(
  :GUILD_CREATE,
  guild.id,
  %{identity: guild.id, data: guild},
  context
)
```

### Update Actions

**Pattern:**

```elixir
Handler.invoke_configured_action(
  :EVENT_NAME,
  %{discord_id: id},     # Or just id if filtering by primary key
  %{
    identity: id,
    data: new_payload
  },
  context
)
```

**Before:**

```elixir
context.resource
|> Ash.Changeset.for_create(:from_discord, %{data: new_guild})
|> Ash.Changeset.set_context(%{
  private: %{ash_discord?: true},
  shared: %{private: %{ash_discord?: true}}
})
|> Ash.create()  # Note: Guild uses upsert pattern via create action
```

**After:**

```elixir
Handler.invoke_configured_action(
  :GUILD_UPDATE,
  new_guild.id,
  %{identity: new_guild.id, data: new_guild},
  context
)
```

### Destroy Actions

**Pattern:**

```elixir
Handler.invoke_configured_action(
  :EVENT_NAME,
  %{discord_id: id},     # Filter to find record(s) to destroy
  %{},                   # Usually empty - just need to find the record
  context
)
```

**Before:**

```elixir
guild_discord_id = old_guild.id

case context.resource
     |> Ash.Query.for_read(:read)
     |> Ash.Query.filter(discord_id == ^guild_discord_id)
     |> Ash.Query.set_context(%{
       private: %{ash_discord?: true},
       shared: %{private: %{ash_discord?: true}}
     })
     |> Ash.read() do
  {:ok, [guild]} ->
    guild |> Ash.destroy(actor: %{role: :bot})
  {:ok, []} ->
    Logger.info("Guild not found")
    :ok
  {:error, error} ->
    {:error, error}
end
```

**After:**

```elixir
Handler.invoke_configured_action(
  :GUILD_DELETE,
  %{discord_id: old_guild.id},
  %{},
  context
)
```

### Read Actions

**Pattern:**

```elixir
Handler.invoke_configured_action(
  :EVENT_NAME,
  filters_map,           # Filters to apply
  additional_args,       # Additional read arguments
  context
)
```

**Example:**

```elixir
Handler.invoke_configured_action(
  :GUILD_LIST,
  %{},                   # No filters
  %{},                   # No additional args
  context
)
```

### Generic Actions

**Pattern:**

```elixir
Handler.invoke_configured_action(
  :EVENT_NAME,
  nil,                   # Identity not used for generic actions
  %{                     # Action arguments
    arg1: value1,
    arg2: value2
  },
  context
)
```

## Common Pitfalls

### ❌ Pitfall 1: Using Primary Key Instead of Discord ID

**Problem:**

```elixir
# This filters by Ash's primary key :id, not :discord_id
Handler.invoke_configured_action(:GUILD_DELETE, old_guild.id, %{}, context)
```

**Solution:**

```elixir
# Use a map to specify the exact filter field
Handler.invoke_configured_action(:GUILD_DELETE, %{discord_id: old_guild.id}, %{}, context)
```

### ❌ Pitfall 2: Not Normalizing Return Values

**Problem:**

```elixir
@spec update(...) :: :ok | {:error, term()}
def update(...) do
  # Returns {:ok, guild} but spec says :ok
  Handler.invoke_configured_action(...)
end
```

**Solution:**

```elixir
@spec update(...) :: :ok | {:error, term()}
def update(...) do
  case Handler.invoke_configured_action(...) do
    {:ok, _} -> :ok
    {:error, e} -> {:error, e}
  end
end
```

### ❌ Pitfall 3: Missing Context Field

**Problem:**

```elixir
# Test creates context without :context field
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: MyResource,
  guild: nil,
  user: nil
  # Missing: context: nil
}
```

**Solution:**

```elixir
# Either add context field explicitly
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: MyResource,
  guild: nil,
  user: nil,
  context: %{private: %{ash_discord?: true}, shared: %{...}}
}

# Or let build_context/3 handle it
context = AshDiscord.Consumer.Handler.build_context(consumer, resource, payload)
```

### ❌ Pitfall 4: Passing Context as Opts

**Problem:**

```elixir
# In invoke_configured_action implementation
def invoke_configured_action(event, identity, arguments, context) do
  # ...
  invoke(resource, action, identity, arguments, context)  # ❌ Passing struct directly
end

defp invoke(resource, action, identity, arguments, opts) do
  Ash.bulk_create([attributes], resource, action.name, opts)  # ❌ Won't work
end
```

**Solution:**

```elixir
def invoke_configured_action(event, identity, arguments, context) do
  # ...
  invoke(resource, action, identity, arguments, scope: context)  # ✅ Pass as scope
end

defp invoke(resource, action, identity, arguments, opts) do
  Ash.bulk_create([attributes], resource, action.name, opts)  # ✅ Works with keyword list
end
```

### ❌ Pitfall 5: Forgetting to Handle Empty Results

**Problem:**

```elixir
defp format_bulk_result(%Ash.BulkResult{status: :success, records: [record]}, :single) do
  {:ok, record}
end
# Missing clause for empty records list
```

**Solution:**

```elixir
defp format_bulk_result(%Ash.BulkResult{status: :success, records: [record]}, :single) do
  {:ok, record}
end

defp format_bulk_result(%Ash.BulkResult{status: :success, records: []}, :single) do
  {:ok, nil}  # Handle destroy that found nothing
end
```

## Testing Considerations

### Update Test Contexts

Ensure test contexts include all required fields:

```elixir
# Before
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: TestApp.Discord.Guild,
  guild: nil,
  user: nil
}

# After
context = %AshDiscord.Context{
  consumer: TestConsumer,
  resource: TestApp.Discord.Guild,
  guild: nil,
  user: nil,
  context: %{private: %{ash_discord?: true}, shared: %{...}}
}
```

### Test Return Value Changes

If you normalized return values, update test assertions:

```elixir
# Before
assert {:ok, _guild} = Guild.update(guild_update, %WSState{}, context)

# After
assert :ok = Guild.update(guild_update, %WSState{}, context)
```

### Add Payload Support for Edge Cases

Handle special payload types that might not have been needed before:

```elixir
# In Guild payload
def new(%Nostrum.Struct.Guild{} = guild), do: super(Map.from_struct(guild))

def new(%Nostrum.Struct.Guild.UnavailableGuild{id: id, unavailable: unavailable}) do
  super(%{
    id: id,
    name: "Unavailable Guild",  # Fill required fields with defaults
    unavailable: unavailable
  })
end
```

## Complete Example

### Before: Manual Ash Operations

```elixir
defmodule AshDiscord.Consumer.Handler.Guild do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(Payloads.Guild.t(), WSState.t(), Context.t())
        :: {:ok, Guild.t()} | {:error, term()}
  def create(guild, _ws_state, context) do
    register_commands(context.consumer, guild)

    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: guild})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
  end

  @spec update(Payloads.GuildUpdate.t(), WSState.t(), Context.t())
        :: :ok | {:error, term()}
  def update(%Payloads.GuildUpdate{new_guild: new_guild}, _ws_state, context) do
    case context.resource
         |> Ash.Changeset.for_create(:from_discord, %{data: new_guild})
         |> Ash.Changeset.set_context(%{
           private: %{ash_discord?: true},
           shared: %{private: %{ash_discord?: true}}
         })
         |> Ash.create() do
      {:ok, _guild_record} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to update guild: #{inspect(error)}")
        {:error, error}
    end
  end

  @spec delete(Payloads.GuildDelete.t(), WSState.t(), Context.t())
        :: :ok | {:error, term()}
  def delete(%Payloads.GuildDelete{old_guild: old_guild, unavailable: false},
             _ws_state,
             context) do
    guild_discord_id = old_guild.id

    case context.resource
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(discord_id == ^guild_discord_id)
         |> Ash.Query.set_context(%{
           private: %{ash_discord?: true},
           shared: %{private: %{ash_discord?: true}}
         })
         |> Ash.read() do
      {:ok, [guild]} ->
        case guild |> Ash.destroy(actor: %{role: :bot}) do
          :ok -> :ok
          {:error, error} -> {:error, error}
        end

      {:ok, []} ->
        Logger.info("Guild #{guild_discord_id} not found")
        :ok

      {:error, error} ->
        Logger.error("Failed to find guild: #{inspect(error)}")
        {:error, error}
    end
  end
end
```

### After: Using `invoke_configured_action`

```elixir
defmodule AshDiscord.Consumer.Handler.Guild do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(Payloads.Guild.t(), WSState.t(), Context.t())
        :: {:ok, Guild.t()} | {:error, term()}
  def create(guild, _ws_state, context) do
    register_commands(context.consumer, guild)

    Handler.invoke_configured_action(
      :GUILD_CREATE,
      {discord_id: guild.id},
      %{identity: guild.id, data: guild},
      context
    )
  end

  @spec update(Payloads.GuildUpdate.t(), WSState.t(), Context.t())
        :: :ok | {:error, term()}
  def update(%Payloads.GuildUpdate{new_guild: new_guild}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_UPDATE,
           %{discord_id, new_guild.id},
           %{identity: new_guild.id, data: new_guild},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec delete(Payloads.GuildDelete.t(), WSState.t(), Context.t())
        :: :ok | {:error, term()}
  def delete(%Payloads.GuildDelete{old_guild: old_guild, unavailable: false},
             _ws_state,
             context) do
    Handler.invoke_configured_action(
      :GUILD_DELETE,
      %{discord_id: old_guild.id},
      %{},
      context
    )
  end
end
```

### Summary of Changes

| Aspect         | Before              | After    | Lines Saved     |
| -------------- | ------------------- | -------- | --------------- |
| **Create**     | 7 lines             | 7 lines  | 0 (but simpler) |
| **Update**     | 18 lines            | 12 lines | 6               |
| **Delete**     | 29 lines            | 7 lines  | 22              |
| **Total**      | 54 lines            | 26 lines | **28 (52%)**    |
| **Complexity** | High                | Low      | Much simpler    |
| **Imports**    | `require Ash.Query` | None     | Cleaner         |

## Migration Checklist

When migrating a handler, use this checklist:

- [ ] Add `alias AshDiscord.Consumer.Handler`
- [ ] Remove `require Ash.Query` (if no longer needed)
- [ ] For each handler function:
  - [ ] Identify the event name
  - [ ] Determine the identity format
  - [ ] Prepare the arguments map
  - [ ] Replace Ash calls with `Handler.invoke_configured_action`
  - [ ] Remove manual `set_context` calls
  - [ ] Normalize return value if needed (`:ok` vs `{:ok, record}`)
- [ ] Update tests:
  - [ ] Add `context` field to test contexts
  - [ ] Update return value assertions
  - [ ] Add any missing payload support
- [ ] Run tests: `mix test`
- [ ] Check for warnings
- [ ] Commit with descriptive message

## Questions?

If you encounter patterns not covered in this guide:

1. Check `lib/ash_discord/consumer/handler/guild.ex` for reference
2. Look at `lib/ash_discord/consumer/handler.ex` for the implementation
3. Check tests in `test/ash_discord/consumer/handler/guild_test.exs`
4. Consult the team or create an issue

---

Follow this guide to refactor the [$ARGUMENTS] handler to use the new
`invoke_configured_action/4` pattern for cleaner, more maintainable code!
