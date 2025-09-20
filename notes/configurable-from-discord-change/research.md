# Codebase Impact Analysis & Targeted Documentation

## Configurable `from_discord` Change for AshDiscord

**Topic:** Create one configurable `from_discord` change that consolidates all
discord transformations from the steward project patterns, making it
configurable for any resource.

---

## Project Dependencies Discovered

### From mix.exs (Current Dependencies)

```elixir
# Core dependencies (Production)
{:ash, "~> 3.0"}              # Ash Framework with change modules & upserts
{:spark, "~> 2.0"}            # DSL framework for configuration extensions
{:nostrum, "~> 0.10"}         # Discord API client with struct definitions

# Development dependencies
{:usage_rules, "~> 0.1"}      # Documentation & usage examples
{:faker, "~> 0.18"}           # Data generation for testing (recently added)
{:mix_test_watch, "~> 1.0"}   # Live test running
{:igniter, "~> 0.6"}          # Code generation and modification
{:sourceror, "~> 1.0"}        # AST manipulation for transformations
{:ex_doc, "~> 0.34"}          # Documentation generation
{:credo, "~> 1.7"}            # Code quality analysis
{:dialyxir, "~> 1.4"}         # Type checking
{:mimic, "~> 1.7"}            # Mocking for tests
{:excoveralls, "~> 0.18"}     # Code coverage
```

---

## Steward Project Analysis - COMPLETE CATALOG FOUND

### **All From Discord Change Modules in Steward Project**

Found **15 complete from_discord change modules** in the steward project:

1. **`Steward.Accounts.User.Changes.FromDiscord`** - User account creation
2. **`Steward.Discord.Guild.Changes.FromDiscord`** - Guild/server management
3. **`Steward.Discord.Channel.Changes.FromDiscord`** - Channel creation with
   permission overwrites
4. **`Steward.Discord.Role.Changes.FromDiscord`** - Role management with API
   fetching
5. **`Steward.Discord.GuildMember.Changes.FromDiscord`** - Member management
   with datetime parsing
6. **`Steward.Discord.Message.Changes.FromDiscord`** - Message handling with
   attachments
7. **`Steward.Discord.Emoji.Changes.FromDiscord`** - Emoji management with key
   normalization
8. **`Steward.Discord.Interaction.Changes.FromDiscord`** - Discord interaction
   processing
9. **`Steward.Discord.MessageAttachment.Changes.FromDiscord`** - File attachment
   handling
10. **`Steward.Discord.MessageReaction.Changes.FromDiscord`** - Reaction
    management
11. **`Steward.Discord.Webhook.Changes.FromDiscord`** - Webhook integration
12. **`Steward.Discord.Invite.Changes.FromDiscord`** - Invite link management
13. **`Steward.Discord.VoiceState.Changes.FromDiscord`** - Voice channel state
14. **`Steward.Discord.TypingIndicator.Changes.FromDiscord`** - Typing
    indicators
15. **`Steward.Discord.Sticker.Changes.FromDiscord`** - Sticker support

### **Universal Patterns Across ALL Steward Changes**

#### **1. Standard Module Structure**

```elixir
defmodule Resource.Changes.FromDiscord do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case get_resource_data(changeset) do
        {:ok, data} -> transform_and_set_attributes(changeset, data)
        {:error, reason} -> Ash.Changeset.add_error(changeset, :discord_fetch_error, reason)
      end
    end)
  end

  defp get_resource_data(changeset) do
    case Ash.Changeset.get_argument(changeset, :discord_struct) do
      %{id: _} = struct -> {:ok, struct}  # Use provided struct
      nil -> fetch_from_api(changeset)     # Fallback to API
      invalid -> {:error, "Invalid discord_struct: #{inspect(invalid)}"}
    end
  end
end
```

#### **2. Data Source Priority (Universal) - STRUCT-FIRST APPROACH**

1. **`discord_struct` argument** → **PRIMARY**: Use provided Discord API data
   directly ⭐
2. **API fetch fallback** → **FALLBACK ONLY**: Use Discord ID to fetch from
   Nostrum API when no struct provided
3. **Error state** → Invalid input or fetch failure

**⚠️ IMPORTANT**: The default and recommended approach is to use existing
Discord struct data from events/webhooks/interactions. API fetching should only
occur when no struct is provided (edge cases like manual sync operations).

#### **3. Field Mapping Patterns**

- **Simple Fields**: `force_change_attribute(:field, data.field)`
- **Transformation**:
  `force_change_attribute(:email, "discord+#{data.id}@steward.local")`
- **Type Conversion**:
  `force_change_attribute(:permissions, to_string(data.permissions))`
- **Default Values**: `force_change_attribute(:nsfw, data.nsfw || false)`
- **Complex Transformation**: Permission overwrites, datetime parsing

#### **4. Relationship Management (Auto-Creation)**

```elixir
# Standard relationship pattern used across ALL modules
Ash.Changeset.manage_relationship(changeset, :relationship_name, discord_id,
  type: :append_and_remove,
  on_no_match: {:create, :from_discord},  # Auto-create missing entities
  use_identities: [:discord_id],
  value_is_key: :discord_id
)
```

#### **5. Special Transformation Patterns**

**DateTime Parsing** (GuildMember):

```elixir
defp maybe_set_joined_at(changeset, joined_at) do
  case DateTime.from_iso8601(joined_at) do
    {:ok, datetime, _offset} ->
      Ash.Changeset.force_change_attribute(changeset, :joined_at, datetime)
    {:error, _} -> changeset
  end
end
```

**Permission Overwrites** (Channel):

```elixir
defp transform_permission_overwrites(overwrites) when is_list(overwrites) do
  Enum.map(overwrites, fn overwrite ->
    %{
      "id" => overwrite.id,
      "type" => overwrite.type,
      "allow" => to_string(overwrite.allow),
      "deny" => to_string(overwrite.deny)
    }
  end)
end
```

**Key Normalization** (Emoji):

```elixir
defp normalize_emoji_struct(emoji_struct) do
  %{
    id: Map.get(emoji_struct, :id) || Map.get(emoji_struct, "id"),
    name: Map.get(emoji_struct, :name) || Map.get(emoji_struct, "name"),
    # Handle both string and atom keys
  }
end
```

---

## Files Requiring Changes

### **New Files to Create**

#### Core Implementation

- `lib/ash_discord/changes/from_discord.ex:1` - Main configurable change module
  - 📖
    [Ash.Resource.Change docs for v3.0](https://hexdocs.pm/ash/Ash.Resource.Change.html)
  - 📖 [Change implementation patterns](https://hexdocs.pm/ash/changes.html)

#### Test Files

- `test/ash_discord/changes/from_discord_test.exs:1` - Comprehensive change
  testing
- `test/support/test_app/discord/configurable_user.ex:1` - Example using new
  change

### **Files to Update (Optional Migration)**

#### Test Resource Updates (Can use new pattern)

- `test/support/test_app/discord/user.ex:34-57` - Could replace with
  configurable
- `test/support/test_app/discord/guild_member.ex:35-62` - Could replace with
  configurable
- `test/support/test_app/discord/message.ex:56-103` - Could replace with
  configurable
- `test/support/test_app/discord/guild.ex:33-64` - Could replace with
  configurable

---

## Consolidated Change Module Design

### **Recommended Configuration Pattern**

Based on steward analysis, a configurable `from_discord` change needs to
support:

1. **Field Mapping Configuration** - Simple field → field mappings
2. **Transformation Functions** - Custom transformation logic per field
3. **Relationship Configuration** - Auto-creation of related Discord entities
4. **Special Type Handling** - DateTime parsing, permission transformations,
   etc.
5. **API Fetch Configuration** - Different Nostrum API endpoints per resource
   type
6. **Error Handling** - Consistent error patterns across all resource types

### **Usage Example Combining All Steward Patterns**

```elixir
# Simple User Pattern (from steward)
create :from_discord do
  change AshDiscord.Changes.FromDiscord,
    discord_type: :user,
    field_mappings: [
      {:discord_id, :id},
      {:discord_username, :username},
      {:discord_avatar, :avatar},
      {:email, fn user -> "discord+#{user.id}@steward.local" end}
    ]
end

# Complex GuildMember Pattern (from steward)
create :from_discord do
  change AshDiscord.Changes.FromDiscord,
    discord_type: :guild_member,
    field_mappings: [
      {:user_discord_id, :user_id},
      {:nick, :nick},
      {:avatar, :avatar},
      {:deaf, fn data -> data.deaf || false end},
      {:mute, fn data -> data.mute || false end},
      {:joined_at, {:datetime_from_iso8601, :joined_at}},
      {:premium_since, {:datetime_from_iso8601, :premium_since}}
    ],
    relationships: [
      {:guild, :guild_discord_id, auto_create: true},
      {:user, :user_discord_id, auto_create: true}
    ],
    api_fetch_function: {Nostrum.Api.Guild, :member, [:guild_discord_id, :user_discord_id]}
end

# Channel with Complex Transformations (from steward)
create :from_discord do
  change AshDiscord.Changes.FromDiscord,
    discord_type: :channel,
    field_mappings: [
      {:discord_id, :id},
      {:name, :name},
      {:type, :type},
      {:position, :position},
      {:topic, :topic},
      {:nsfw, fn data -> data.nsfw || false end},
      {:parent_id, :parent_id},
      {:permission_overwrites, {:transform_permission_overwrites, :permission_overwrites}}
    ],
    relationships: [
      {:guild, :guild_id, auto_create: true}
    ],
    api_fetch_function: {Nostrum.Api.Channel, :get, [:discord_id]}
end
```

---

## Integration Points

### **Ash Framework Integration**

- **Change Module Pattern**: Uses `Ash.Resource.Change` behavior for custom
  transformations
  - 📖
    [Ash Change Module guide](https://hexdocs.pm/ash/changes.html#custom-changes)
- **Upsert Strategy**: Identity-based upserts with configurable update fields
  - 📖
    [Ash Upsert documentation](https://hexdocs.pm/ash/identities.html#upserts)

### **Nostrum Discord API Integration**

- **Discord Structs**: Integration with all Nostrum struct definitions
  - 📖
    [Nostrum User struct](https://kraigie.github.io/nostrum/Nostrum.Struct.User.html)
  - 📖
    [Nostrum Guild struct](https://kraigie.github.io/nostrum/Nostrum.Struct.Guild.html)
  - 📖
    [Nostrum Guild Member struct](https://kraigie.github.io/nostrum/Nostrum.Struct.Guild.Member.html)
  - 📖
    [Nostrum Message struct](https://kraigie.github.io/nostrum/Nostrum.Struct.Message.html)
  - 📖
    [Nostrum Channel struct](https://kraigie.github.io/nostrum/Nostrum.Struct.Channel.html)
  - 📖
    [Nostrum Role struct](https://kraigie.github.io/nostrum/Nostrum.Struct.Guild.Role.html)

---

## Test Impact & Patterns

### Tests Requiring Updates

- **New comprehensive test suite** for configurable change module
- **Test coverage for all Discord entity types** found in steward
- **Integration tests** with different configuration patterns

### Current Testing Patterns

- **Data Layer**: `Ash.DataLayer.Ets` for fast in-memory testing
- **Mock Data**: Faker for generating test Discord data
- **Mocking Strategy**: Mimic for Discord API calls

---

## Configuration & Environment

### **No new dependencies needed** - All functionality available through existing:

- **Ash 3.0**: Change modules and upsert patterns
- **Spark 2.0**: Configuration validation (if needed)
- **Nostrum 0.10**: All Discord struct definitions
- **Faker 0.18**: Test data generation

---

## Risk Assessment

### **Low Risk Areas**

- **Backward Compatibility**: New change can coexist with existing manual
  implementations
- **Performance**: Change modules are compile-time optimized by Ash
- **Testing**: Can reuse existing test patterns from steward project

### **Medium Risk Areas**

- **Configuration Complexity**: Supporting all 15 Discord entity types requires
  careful design
- **Transformation Complexity**: Some transformations (permission overwrites,
  datetime parsing) are complex

### **Mitigation Strategies**

- **Start Simple**: Implement core field mapping first, add complex
  transformations incrementally
- **Copy Proven Patterns**: Reuse exact transformation logic from steward
  project
- **Comprehensive Testing**: Test against steward's existing test cases

---

## Success Criteria

Research phase is complete when:

- ✅ Complete file-level impact map created with specific locations
- ✅ All existing dependencies and patterns documented
- ✅ **All 15 steward from_discord change modules cataloged and analyzed**
- ✅ **Universal transformation patterns identified across all modules**
- ✅ **Consolidated configuration design created**
- ✅ Integration points and configuration changes identified
- ✅ Test impact assessment completed
- ✅ Risk assessment with mitigation strategies provided
- ✅ Ready for **plan** phase with surgical precision and all resources

---

## Next Phase

Ready for **plan** phase to create strategic implementation planning using all
discovered steward patterns and proven transformation logic.
