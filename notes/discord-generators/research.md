# Discord Generator Functions Research Document

## Project Dependencies Discovered

### From mix.exs (Actual Dependencies and Versions)

- **Ash Framework**: ash ~> 3.0 (Core resource framework)
- **Spark DSL**: spark ~> 2.0 (DSL processing framework)
- **Nostrum**: nostrum ~> 0.10 (Discord API library - runtime: Mix.env() !=
  :test)
- **Faker**: faker ~> 0.18 (Data generation library - only: [:test])
- **Mimic**: mimic ~> 1.7 (Mocking library - only: :test)

### Current Testing Framework

- **ExUnit**: Built-in Elixir testing framework
- **Data Layer**: Ash.DataLayer.Ets (in-memory for tests)
- **Mocking Strategy**: Mimic for external API calls
- **Test Support Path**: `test/support/` (included in elixirc_paths for :test)

## Files Requiring Changes

### Primary Generator File

- `test/support/generators/discord.ex:1` - Currently empty, needs complete
  implementation
  - 📖 [ExUnit.Case docs](https://hexdocs.pm/ex_unit/ExUnit.Case.html) - Testing
    framework
  - 📖 [Faker v0.18 docs](https://hexdocs.pm/faker/0.18.0/) - Data generation
    library

### Test Files Using Discord Structs

- `test/ash_discord/interaction_router_test.exs:21-334` - Uses hardcoded Discord
  interaction structs
  - 📖
    [Nostrum.Struct.Interaction docs](https://hexdocs.pm/nostrum/Nostrum.Struct.Interaction.html) -
    Discord interaction structure
- `test/ash_discord/command_test.exs:8-16` - Uses AshDiscord internal structs
  (not Discord API structs)

## Existing Patterns Found

### Resource Helper Methods Pattern

All test Discord resources already include `discord_struct/1` helper functions:

- **TestApp.Discord.User:102** - `discord_struct/1` helper

  ```elixir
  def discord_struct(attrs) do
    %{
      id: Map.get(attrs, :discord_id),
      username: Map.get(attrs, :username),
      # ... other fields
    }
  end
  ```

- **TestApp.Discord.Message:151** - Similar pattern with author nesting
- **TestApp.Discord.Guild:104** - Simple field mapping
- **TestApp.Discord.GuildMember:90** - Complex nested structure

### Test Data Patterns Found

From `test/ash_discord/interaction_router_test.exs:20-334`:

- **Discord Interaction Structure**: Used in 12+ test cases
- **Hardcoded Values**: Many magic numbers (IDs, tokens)
- **Type Mapping**: Discord option types (3=string, 4=integer, 5=boolean)
- **Nested Structures**: member.user, data.options patterns

## Integration Points

### Nostrum Struct Integration

- **Available Structs**: 18+ core Discord entities in
  `deps/nostrum/lib/nostrum/struct/`
  - User, Guild, Channel, Message, Role, Interaction, Embed, etc.
  - 📖
    [Nostrum.Struct.User](https://hexdocs.pm/nostrum/Nostrum.Struct.User.html) -
    Core user structure
  - 📖
    [Nostrum.Struct.Guild](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.html) -
    Guild/server structure
  - 📖
    [Nostrum.Struct.Message](https://hexdocs.pm/nostrum/Nostrum.Struct.Message.html) -
    Message structure

### Project Resource Integration

- **TestApp.Discord Domain**: 4 test resources (User, Message, Guild,
  GuildMember)
- **Identity Fields**: All use `:discord_id` for Discord entity mapping
- **Upsert Pattern**: All have `:from_discord` actions for API data integration

## Required New Dependencies/Patterns

### Discord Snowflake ID Generation

⚠️ **Custom Implementation Required:**

- **Issue**: Faker doesn't generate Discord snowflake IDs
- **Solution**: Custom function needed for realistic Discord ID generation
- **Pattern**: Discord epoch (1420070400000) + timestamp + worker + process +
  increment

```elixir
# Discord snowflake format: 64-bit integer
# timestamp (42 bits) | worker_id (5 bits) | process_id (5 bits) | increment (12 bits)
```

### Generator Module Structure

- **Approach**: Single module in `test/support/generators/discord.ex`
- **Pattern**: Follow existing `discord_struct/1` helpers but with Faker
  integration
- **Organization**: One function per Discord entity type

## Risk Assessment

### Low Risk Areas

- **Faker Integration**: Well-documented library, safe data generation
- **Existing Helper Pattern**: Successfully used in current resources
- **Test-Only Code**: No production impact

### Medium Risk Areas

- **Snowflake ID Generation**: Custom implementation needed, must be realistic
- **Discord API Accuracy**: Generated data must match Discord API specifications
- **Relationship Dependencies**: Some structs reference others (user_id,
  guild_id)

### Dependencies Between Structs

- **User → Guild**: Users exist in guilds as members
- **Message → User/Channel**: Messages have authors and channels
- **Role → Guild**: Roles belong to guilds
- **Interaction → User/Guild/Channel**: Complex nested relationships

## Discord Structs Requiring Generators

### Core Entity Structs (Priority 1)

1. **Nostrum.Struct.User** - Discord user accounts

   - Fields: id, username, discriminator, global_name, avatar, bot, public_flags
   - Usage: Authentication, message authors, interaction users

2. **Nostrum.Struct.Guild** - Discord servers/guilds

   - Fields: id, name, icon, description, owner_id, roles, channels,
     member_count
   - Usage: Server management, configuration commands

3. **Nostrum.Struct.Channel** - Discord channels

   - Fields: id, type, guild_id, name, topic, position, permission_overwrites
   - Usage: Message routing, channel-specific commands

4. **Nostrum.Struct.Message** - Discord messages

   - Fields: id, content, author, channel_id, guild_id, timestamp, attachments
   - Usage: Message processing, content analysis

5. **Nostrum.Struct.Interaction** - Discord slash command interactions
   - Fields: id, type, data, guild_id, channel_id, member, user, token
   - Usage: Command routing, interaction handling

### Guild Management Structs (Priority 2)

6. **Nostrum.Struct.Guild.Role** - Discord roles

   - Fields: id, name, color, permissions, position, mentionable
   - Usage: Permission management, role assignment

7. **Nostrum.Struct.Guild.Member** - Guild membership
   - Fields: user_id, guild_id, nick, roles, joined_at, premium_since
   - Usage: Member management, role tracking

### Content Structs (Priority 3)

8. **Nostrum.Struct.Embed** - Rich message embeds

   - Fields: title, description, color, fields, footer, image, thumbnail
   - Usage: Rich message formatting, bot responses

9. **Nostrum.Struct.Emoji** - Custom emojis
   - Fields: id, name, animated, managed, roles
   - Usage: Emoji reactions, custom server emojis

### Command/Interaction Structs (Priority 4)

10. **Nostrum.Struct.ApplicationCommand** - Slash commands

    - Fields: id, application_id, name, description, options, type
    - Usage: Command registration, option validation

11. **Nostrum.Struct.ApplicationCommandInteractionData** - Command data
    - Fields: id, name, options, resolved, type
    - Usage: Command parameter parsing

### Utility Structs (Priority 5)

12. **Nostrum.Struct.Webhook** - Discord webhooks

    - Fields: id, type, guild_id, channel_id, user, name, avatar, token
    - Usage: External integrations, automated messages

13. **Nostrum.Struct.Invite** - Discord invites
    - Fields: code, guild, channel, inviter, target_user, expires_at
    - Usage: Server invitations, link generation

## Faker Integration Strategy

### Discord-Appropriate Data Mapping

#### User Data Generation

```elixir
# Username patterns
Faker.Internet.user_name()           # "elizabeth2056"
"#{Faker.Person.first_name()}#{Faker.Util.digit()}"  # "Sarah7"

# Display names
Faker.Person.name()                  # "Mrs. Abe Rolfson MD"
Faker.Person.first_name()            # "Joany"

# Avatar URLs
"#{Faker.UUID.v4()}.png"            # Discord CDN style
Faker.Avatar.image_url(128, 128)     # External avatar service
```

#### Content Generation

```elixir
# Message content
Faker.Lorem.sentence(3..15)          # 3-15 word sentences
Faker.Lorem.paragraph(1..3)          # Multi-sentence content

# Descriptions (guilds, embeds)
Faker.Lorem.sentence(5..20)          # Longer descriptive content

# Channel/Guild names
"#{Faker.Lorem.word()}-#{Faker.Lorem.word()}"  # "general-chat"
"#{Faker.Person.first_name()}'s Server"        # "Sarah's Server"
```

#### Discord IDs (Snowflakes)

```elixir
# Custom snowflake generation needed
defp generate_discord_snowflake do
  timestamp = (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - 1420070400000
  worker_id = Faker.random_between(0, 31)
  process_id = Faker.random_between(0, 31)
  increment = Faker.random_between(0, 4095)

  (timestamp <<< 22) ||| (worker_id <<< 17) ||| (process_id <<< 12) ||| increment
end
```

#### Timestamps

```elixir
# Recent activity
Faker.DateTime.backward(30)          # Last 30 days
Faker.DateTime.forward(60)           # Next 60 days

# Convert to Discord format
datetime |> DateTime.to_unix()       # Unix timestamp
datetime |> DateTime.to_iso8601()    # ISO 8601 string
```

#### Colors (Roles, Embeds)

```elixir
# Hex colors
Faker.Color.rgb_hex()                # "D6D98B"
"##{Faker.Color.rgb_hex()}"         # "#D6D98B"

# Integer colors (Discord format)
{r, g, b} = Faker.Color.rgb_decimal()
color_int = (r <<< 16) + (g <<< 8) + b
```

## Third-Party Integrations & External Services

### Faker Library Integration

- **Service**: Faker v0.18 data generation
- **Integration Type**: Direct function calls for realistic test data
- **Context-Specific Documentation**:
  - 📖 [Faker.Person](https://hexdocs.pm/faker/0.18.0/Faker.Person.html) - Names
    and personal data
  - 📖 [Faker.Internet](https://hexdocs.pm/faker/0.18.0/Faker.Internet.html) -
    URLs, usernames, emails
  - 📖 [Faker.Lorem](https://hexdocs.pm/faker/0.18.0/Faker.Lorem.html) - Text
    content generation
  - 📖 [Faker.DateTime](https://hexdocs.pm/faker/0.18.0/Faker.DateTime.html) -
    Date/time generation
  - 📖 [Faker.Color](https://hexdocs.pm/faker/0.18.0/Faker.Color.html) - Color
    generation
  - 📖 [Faker.UUID](https://hexdocs.pm/faker/0.18.0/Faker.UUID.html) - UUID
    generation
  - 📖 [Faker.Avatar](https://hexdocs.pm/faker/0.18.0/Faker.Avatar.html) -
    Avatar URL generation
- **Version Information**: Current version: faker 0.18.0

### Nostrum Discord API Library

- **Service**: Nostrum v0.10 Discord API client
- **Integration Type**: Struct definitions and type specifications
- **Context-Specific Documentation**:
  - 📖 [Nostrum Documentation](https://hexdocs.pm/nostrum/) - Complete API
    reference
  - 📖
    [Nostrum.Struct](https://hexdocs.pm/nostrum/api-reference.html#modules-nostrum-struct) -
    All Discord struct modules
  - 📖 [Discord API Reference](https://discord.com/developers/docs/reference) -
    Official Discord API specs
- **Version Information**: Current version: nostrum 0.10 (runtime: Mix.env() !=
  :test)

## Implementation Approach

### Generator Module Design

```elixir
defmodule AshDiscord.Test.Generators.Discord do
  @moduledoc """
  Generator functions for Discord structs using Faker for realistic test data.
  """

  # Core entity generators
  def user(attrs \\ %{})
  def guild(attrs \\ %{})
  def channel(attrs \\ %{})
  def message(attrs \\ %{})
  def interaction(attrs \\ %{})

  # Utility functions
  defp generate_discord_snowflake()
  defp merge_attrs(defaults, overrides)
end
```

### Integration with Existing Helpers

- **Extend**: Existing `discord_struct/1` helpers in test resources
- **Replace**: Hardcoded test data with generated data
- **Maintain**: Backward compatibility with current test patterns

### Usage Examples

```elixir
# In test files
import AshDiscord.Test.Generators.Discord

# Generate complete Discord user
user_struct = user(%{username: "testuser"})

# Generate interaction for command testing
interaction = interaction(%{
  data: %{name: "hello", options: []},
  guild_id: generate_discord_snowflake()
})

# Generate with relationships
guild_struct = guild()
channel_struct = channel(%{guild_id: guild_struct.id})
message_struct = message(%{channel_id: channel_struct.id})
```

## Unclear Areas Requiring Clarification

### Struct Format Preferences

- **Question**: Should generators return raw maps or Nostrum struct instances?
- **Context**: Existing `discord_struct/1` helpers return maps, but Nostrum
  provides actual structs
- **Options**:
  1. Raw maps (current pattern compatibility)
  2. Nostrum structs (type safety)
  3. Both (flexibility)

### Test Data Realism Level

- **Question**: How realistic should generated data be?
- **Context**: Balance between realistic Discord patterns and test isolation
- **Options**:
  1. Highly realistic (actual Discord patterns)
  2. Simple/predictable (easier testing)
  3. Configurable (both options available)

### Relationship Handling

- **Question**: Should generators automatically create related entities?
- **Context**: Messages need users/channels, members need users/guilds
- **Options**:
  1. Auto-generate dependencies
  2. Require explicit dependency passing
  3. Smart defaults with override capability

### Performance Considerations

- **Question**: Should generated data be cached for test performance?
- **Context**: Large test suites may benefit from reusing generated entities
- **Options**:
  1. Generate fresh data each time
  2. Cache common entities per test
  3. Configurable caching strategy

## Success Criteria

Research phase complete when:

- ✅ **Complete project analysis**: All Discord-related code patterns identified
- ✅ **Faker integration strategy**: Comprehensive mapping of Discord fields to
  Faker functions
- ✅ **Nostrum struct inventory**: All available Discord structs catalogued with
  field definitions
- ✅ **Existing pattern analysis**: Current `discord_struct/1` helpers and test
  patterns documented
- ✅ **Risk assessment**: Potential issues and mitigation strategies identified
- ✅ **Implementation roadmap**: Clear priority order and approach defined
- ✅ **Integration points**: File locations and change requirements mapped
- ❓ **Clarification items**: Key decisions flagged for user input

**Ready for planning phase** with comprehensive understanding of requirements,
constraints, and implementation approach.

## Next Phase: Implementation Planning

The research provides everything needed to create a detailed implementation
plan:

1. **Generator module structure** and organization
2. **Faker function mapping** for each Discord field type
3. **Nostrum struct compatibility** requirements
4. **Test integration strategy** with existing patterns
5. **Performance and usability** considerations

Implementation can proceed systematically through the priority-ordered Discord
struct types with confidence in the technical approach and full understanding of
project constraints.
