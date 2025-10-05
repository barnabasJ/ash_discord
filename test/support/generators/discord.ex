defmodule AshDiscord.Test.Generators.Discord do
  import Bitwise

  @moduledoc """
  Generator functions for Discord structs using Faker for realistic test data.

  This module provides functions to generate Discord API entities with realistic
  data using the Faker library. All generators accept an optional attributes map
  to override default values.

  ## Usage

  Import the module in your test files:

      import AshDiscord.Test.Generators.Discord

  Generate Discord entities:

      # Generate a user
      user = user(%{username: "testuser"})

      # Generate a complete interaction
      interaction = interaction(%{
        guild_id: generate_snowflake(),
        data: %{name: "hello", options: []}
      })

      # Generate related entities
      guild_struct = guild()
      channel_struct = channel(%{guild_id: guild_struct.id})
      message_struct = message(%{channel_id: channel_struct.id})

  ## Available Generators

  ### Core Entities
  - `user/1` - Discord user accounts
  - `guild/1` - Discord servers/guilds
  - `channel/1` - Discord channels
  - `message/1` - Discord messages
  - `interaction/1` - Slash command interactions
  - `member/1` - Guild members

  ### Additional Entities
  - `role/1` - Guild roles
  - `embed/1` - Message embeds
  - `emoji/1` - Custom emojis
  - `webhook/1` - Webhooks
  - `invite/1` - Server invites
  - `application_command/1` - Command definitions
  - `interaction_data/1` - Interaction command data
  - `option/1` - Command options
  - `permission_overwrite/1` - Channel permission overwrites
  - `voice_state/1` - Voice channel connection states
  - `message_attachment/1` - Message file attachments
  - `message_reaction/1` - Message reactions with emoji data
  - `guild_member/1` - Guild members (alias for member/1)
  - `sticker/1` - Discord stickers
  - `typing_indicator/1` - Typing indicators

  ## Utilities

  - `generate_snowflake/0` - Generate Discord snowflake IDs
  """

  @doc """
  Generates a Discord snowflake ID.

  Discord snowflakes are 64-bit integers with the following structure:
  - timestamp (42 bits) - milliseconds since Discord epoch (Jan 1, 2015)
  - worker_id (5 bits) - internal worker that generated the ID
  - process_id (5 bits) - internal process ID
  - increment (12 bits) - incrementing counter

  ## Examples

      iex> id = generate_snowflake()
      iex> is_integer(id) and id > 0
      true
  """
  def generate_snowflake do
    # Discord epoch: January 1, 2015, 00:00:00 UTC
    discord_epoch = 1_420_070_400_000
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    worker_id = Faker.random_between(0, 31)
    process_id = Faker.random_between(0, 31)
    increment = Faker.random_between(0, 4095)

    (timestamp - discord_epoch) <<< 22 |||
      worker_id <<< 17 |||
      process_id <<< 12 |||
      increment
  end

  @doc """
  Generates a Discord user struct.

  ## Options

  - `:id` - User ID (defaults to generated snowflake)
  - `:username` - Username (defaults to generated username)
  - `:discriminator` - 4-digit discriminator (defaults to random)
  - `:global_name` - Display name (defaults to generated name)
  - `:avatar` - Avatar hash (defaults to generated UUID)
  - `:bot` - Whether user is a bot (defaults to false)
  - `:public_flags` - User public flags (defaults to 0)

  ## Examples

      iex> user = user(%{username: "testuser"})
      iex> user.username
      "testuser"
      iex> is_integer(user.id)
      true
  """
  def user(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      username: Faker.Internet.user_name(),
      discriminator: String.pad_leading("#{Faker.random_between(1, 9999)}", 4, "0"),
      global_name: Faker.Person.name(),
      avatar: "#{Faker.UUID.v4()}",
      bot: false,
      public_flags: 0
    }

    struct(Nostrum.Struct.User, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord guild (server) struct.

  ## Options

  - `:id` - Guild ID (defaults to generated snowflake)
  - `:name` - Guild name (defaults to generated name)
  - `:icon` - Icon hash (defaults to generated UUID)
  - `:description` - Guild description (defaults to generated sentence)
  - `:owner_id` - Owner user ID (defaults to generated snowflake)
  - `:region` - Voice region (defaults to "us-east")
  - `:verification_level` - Verification level (defaults to 0)
  - `:default_message_notifications` - Notification level (defaults to 0)
  - `:explicit_content_filter` - Content filter level (defaults to 0)
  - `:features` - Guild features (defaults to empty list)
  - `:mfa_level` - MFA requirement level (defaults to 0)
  - `:member_count` - Member count (defaults to random between 10-1000)

  ## Examples

      iex> guild = guild(%{name: "My Server"})
      iex> guild.name
      "My Server"
  """
  def guild(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      name: "#{Faker.Person.first_name()}'s #{Faker.Util.pick(["Server", "Guild", "Community"])}",
      icon: Faker.UUID.v4(),
      description: Faker.Lorem.sentence(5..20),
      owner_id: generate_snowflake(),
      region: "us-east",
      verification_level: 0,
      default_message_notifications: 0,
      explicit_content_filter: 0,
      features: [],
      mfa_level: 0,
      member_count: Faker.random_between(10, 1000)
    }

    struct(Nostrum.Struct.Guild, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord channel struct.

  ## Options

  - `:id` - Channel ID (defaults to generated snowflake)
  - `:type` - Channel type (defaults to 0 for text channel)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:position` - Channel position (defaults to random 0-50)
  - `:name` - Channel name (defaults to generated name)
  - `:topic` - Channel topic (defaults to generated sentence)
  - `:nsfw` - Whether channel is NSFW (defaults to false)
  - `:last_message_id` - Last message ID (defaults to nil)
  - `:bitrate` - Voice channel bitrate (defaults to 64000)
  - `:user_limit` - Voice channel user limit (defaults to 0)
  - `:rate_limit_per_user` - Slowmode seconds (defaults to 0)

  ## Examples

      iex> channel = channel(%{name: "general", type: 0})
      iex> channel.name
      "general"
      iex> channel.type
      0
  """
  def channel(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      type: 0,
      guild_id: generate_snowflake(),
      position: Faker.random_between(0, 50),
      name: "#{Faker.Lorem.word()}-#{Faker.Lorem.word()}",
      topic: Faker.Lorem.sentence(3..15),
      nsfw: false,
      last_message_id: nil,
      bitrate: 64_000,
      user_limit: 0,
      rate_limit_per_user: 0
    }

    struct(Nostrum.Struct.Channel, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord message struct.

  ## Options

  - `:id` - Message ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to nil)
  - `:author` - Author user struct (defaults to generated user)
  - `:content` - Message content (defaults to generated sentence)
  - `:timestamp` - Message timestamp (defaults to recent datetime)
  - `:edited_timestamp` - Edit timestamp (defaults to nil)
  - `:tts` - Text-to-speech (defaults to false)
  - `:mention_everyone` - Whether @everyone is mentioned (defaults to false)
  - `:mentions` - User mentions (defaults to empty list)
  - `:mention_roles` - Role mentions (defaults to empty list)
  - `:attachments` - Message attachments (defaults to empty list)
  - `:embeds` - Message embeds (defaults to empty list)
  - `:reactions` - Message reactions (defaults to nil)
  - `:pinned` - Whether message is pinned (defaults to false)
  - `:webhook_id` - Webhook ID if from webhook (defaults to nil)
  - `:type` - Message type (defaults to 0)

  ## Examples

      iex> message = message(%{content: "Hello world"})
      iex> message.content
      "Hello world"
  """
  def message(attrs \\ %{}) do
    author_user = user()

    # Generate member if this is a guild message (80% of messages)
    has_guild = Faker.Util.pick([true, true, true, true, false])
    guild_id_value = if has_guild, do: generate_snowflake(), else: nil

    member_value =
      if has_guild do
        %Nostrum.Struct.Guild.Member{
          user_id: author_user.id,
          nick:
            if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
          roles: [],
          joined_at: Faker.DateTime.backward(365),
          premium_since: nil,
          communication_disabled_until: nil,
          deaf: false,
          mute: false,
          pending: false,
          flags: 0
        }
      else
        nil
      end

    defaults = %{
      id: generate_snowflake(),
      channel_id: generate_snowflake(),
      guild_id: guild_id_value,
      author: author_user,
      member: member_value,
      content: Faker.Lorem.sentence(3..50),
      # timestamp should be DateTime, not ISO8601 string
      timestamp: Faker.DateTime.backward(30),
      edited_timestamp: nil,
      tts: false,
      mention_everyone: false,
      mentions: [],
      mention_roles: [],
      attachments: [],
      embeds: [],
      reactions: nil,
      pinned: false,
      webhook_id: nil,
      type: 0
    }

    result = merge_attrs(defaults, attrs)

    # Add edited timestamp 25% of the time, but only if not explicitly set
    final_result =
      if Map.has_key?(attrs, :edited_timestamp) do
        result
      else
        if Faker.Util.pick([true, false, false, false]) do
          # edited_timestamp should be DateTime, add 1-2 hours after original timestamp
          edited_time = DateTime.add(result.timestamp, Faker.random_between(3600, 7200), :second)
          Map.put(result, :edited_timestamp, edited_time)
        else
          result
        end
      end

    struct(Nostrum.Struct.Message, final_result)
  end

  @doc """
  Generates a Discord interaction struct for slash commands.

  ## Options

  - `:id` - Interaction ID (defaults to generated snowflake)
  - `:application_id` - Application ID (defaults to generated snowflake)
  - `:type` - Interaction type (defaults to 2 for APPLICATION_COMMAND)
  - `:data` - Interaction data (defaults to generated data)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:member` - Guild member (defaults to generated member)
  - `:user` - User (defaults to generated user)
  - `:token` - Interaction token (defaults to generated token)
  - `:version` - Version (defaults to 1)

  ## Examples

      iex> interaction = interaction(%{data: %{name: "hello"}})
      iex> interaction.data.name
      "hello"
  """
  def interaction(attrs \\ %{}) do
    interaction_user = user()

    # 20% DM interactions
    has_guild = Faker.Util.pick([true, true, true, true, false])

    # Vary interaction types: 60% commands, 20% components, 20% modals
    interaction_type = Faker.Util.pick([2, 2, 2, 3, 5])

    # Adjust data based on type
    data_value =
      case interaction_type do
        1 ->
          nil

        2 ->
          %{
            name: Faker.Util.pick(["hello", "help", "ping", "info"]),
            options: []
          }

        3 ->
          %{
            component_type: 2,
            custom_id: "button_#{Faker.UUID.v4()}"
          }

        4 ->
          %{
            name: "search",
            options: [%{name: "query", value: Faker.Lorem.word()}]
          }

        5 ->
          %{
            custom_id: "modal_#{Faker.UUID.v4()}",
            components: []
          }
      end

    defaults = %{
      id: generate_snowflake(),
      application_id: generate_snowflake(),
      type: interaction_type,
      data: data_value,
      guild_id: if(has_guild, do: generate_snowflake(), else: nil),
      channel_id: generate_snowflake(),
      channel:
        if(Faker.Util.pick([true, false, false]),
          do: %{
            id: generate_snowflake(),
            type: 0,
            name: Faker.Lorem.word()
          },
          else: nil
        ),
      member:
        if has_guild do
          struct(Nostrum.Struct.Guild.Member, %{
            user_id: interaction_user.id,
            nick: nil,
            roles: [],
            joined_at: Faker.DateTime.backward(365),
            premium_since: nil,
            communication_disabled_until: nil,
            deaf: false,
            mute: false,
            pending: false,
            flags: 0
          })
        else
          nil
        end,
      user: interaction_user,
      token: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
      version: 1,
      message:
        if(interaction_type == 3,
          do: %{
            id: generate_snowflake(),
            channel_id: generate_snowflake(),
            content: Faker.Lorem.sentence(1..10)
          },
          else: nil
        ),
      locale: Faker.Util.pick(["en-US", "en-GB", "fr", "de", "es-ES", "pt-BR", "ja", "zh-CN"]),
      guild_locale: if(has_guild, do: Faker.Util.pick(["en-US", "en-GB", "fr", "de"]), else: nil)
    }

    struct(Nostrum.Struct.Interaction, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord guild member struct.

  ## Options

  - `:user_id` - User ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:nick` - Nickname (defaults to nil)
  - `:roles` - Role IDs (defaults to empty list)
  - `:joined_at` - Join timestamp (defaults to past datetime)
  - `:premium_since` - Nitro boost timestamp (defaults to nil)
  - `:deaf` - Whether deafened (defaults to false)
  - `:mute` - Whether muted (defaults to false)
  - `:pending` - Whether pending verification (defaults to false)

  ## Examples

      iex> member = member(%{nick: "TestNick"})
      iex> member.nick
      "TestNick"
  """
  def member(attrs \\ %{}) do
    member_user = user()

    defaults = %{
      user_id: member_user.id,
      nick: if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
      roles: [],
      # joined_at should be DateTime, not Unix timestamp
      joined_at: Faker.DateTime.backward(365),
      # premium_since should be DateTime 25% of the time for boosted members
      premium_since:
        if(Faker.Util.pick([true, false, false, false]),
          do: Faker.DateTime.backward(30),
          else: nil
        ),
      # communication_disabled_until should be DateTime 5% of the time for timed-out members
      communication_disabled_until:
        if(Faker.Util.pick([true] ++ List.duplicate(false, 19)),
          do: Faker.DateTime.forward(7),
          else: nil
        ),
      deaf: false,
      mute: false,
      pending: false,
      flags: 0
    }

    struct(Nostrum.Struct.Guild.Member, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord role struct.

  ## Options

  - `:id` - Role ID (defaults to generated snowflake)
  - `:name` - Role name (defaults to generated name)
  - `:color` - Role color as integer (defaults to generated color)
  - `:hoist` - Whether role is displayed separately (defaults to false)
  - `:position` - Role position (defaults to random 1-20)
  - `:permissions` - Permission bitfield (defaults to basic permissions)
  - `:managed` - Whether role is managed by integration (defaults to false)
  - `:mentionable` - Whether role is mentionable (defaults to true)

  ## Examples

      iex> role = role(%{name: "Moderator", color: 0xFF0000})
      iex> role.name
      "Moderator"
      iex> role.color
      16711680
  """
  def role(attrs \\ %{}) do
    {r, g, b} = Faker.Color.rgb_decimal()

    defaults = %{
      id: generate_snowflake(),
      name:
        Faker.Util.pick([
          Faker.Color.fancy_name(),
          "#{Faker.Person.title()}",
          "#{Faker.Lorem.word() |> String.capitalize()}"
        ]),
      color: rgb_to_int({r, g, b}),
      hoist: false,
      position: Faker.random_between(1, 20),
      permissions: 104_324_673,
      managed: false,
      mentionable: true
    }

    struct(Nostrum.Struct.Guild.Role, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord embed struct for rich messages.

  ## Options

  - `:title` - Embed title (defaults to generated title)
  - `:description` - Embed description (defaults to generated paragraph)
  - `:url` - Embed URL (defaults to nil)
  - `:timestamp` - Embed timestamp (defaults to nil)
  - `:color` - Embed color (defaults to generated color)
  - `:footer` - Footer object (defaults to nil)
  - `:image` - Image object (defaults to nil)
  - `:thumbnail` - Thumbnail object (defaults to nil)
  - `:author` - Author object (defaults to nil)
  - `:fields` - Fields array (defaults to empty list)

  ## Examples

      iex> embed = embed(%{title: "Test Embed"})
      iex> embed.title
      "Test Embed"
  """
  def embed(attrs \\ %{}) do
    {r, g, b} = Faker.Color.rgb_decimal()

    defaults = %{
      title: Faker.Lorem.sentence(2..8),
      description: Faker.Lorem.paragraph(1..3),
      url: nil,
      timestamp: nil,
      color: rgb_to_int({r, g, b}),
      footer: nil,
      image: nil,
      thumbnail: nil,
      author: nil,
      fields: []
    }

    struct(Nostrum.Struct.Embed, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord emoji struct.

  ## Options

  - `:id` - Emoji ID (defaults to generated snowflake for custom emojis)
  - `:name` - Emoji name (defaults to generated name)
  - `:animated` - Whether emoji is animated (defaults to false)
  - `:managed` - Whether emoji is managed (defaults to false)
  - `:require_colons` - Whether emoji requires colons (defaults to true)
  - `:roles` - Role IDs that can use emoji (defaults to empty list)

  ## Examples

      iex> emoji = emoji(%{name: "custom_emoji"})
      iex> emoji.name
      "custom_emoji"
  """
  def emoji(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      name: Faker.Lorem.word(),
      animated: false,
      managed: false,
      require_colons: true,
      roles: []
    }

    struct(Nostrum.Struct.Emoji, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord webhook struct.

  ## Options

  - `:id` - Webhook ID (defaults to generated snowflake)
  - `:type` - Webhook type (defaults to 1)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:user` - User who created webhook (defaults to generated user)
  - `:name` - Webhook name (defaults to generated name)
  - `:avatar` - Webhook avatar (defaults to nil)
  - `:token` - Webhook token (defaults to generated token)

  ## Examples

      iex> webhook = webhook(%{name: "Test Webhook"})
      iex> webhook.name
      "Test Webhook"
  """
  def webhook(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      type: Faker.Util.pick([1, 2, 3]),
      guild_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      user: user(),
      name: "#{Faker.Lorem.word()} Webhook",
      avatar: nil,
      token: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}"
    }

    struct(Nostrum.Struct.Webhook, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord invite struct.

  ## Options

  - `:code` - Invite code (defaults to generated code)
  - `:guild` - Guild object (defaults to generated guild)
  - `:channel` - Channel object (defaults to generated channel)
  - `:inviter` - User who created invite (defaults to generated user)
  - `:target_user` - Target user for invite (defaults to nil)
  - `:expires_at` - Expiration timestamp (defaults to future date)
  - `:max_uses` - Maximum uses (defaults to 0 for unlimited)
  - `:uses` - Current uses (defaults to 0)

  ## Examples

      iex> invite = invite(%{code: "abc123"})
      iex> invite.code
      "abc123"
  """
  def invite(attrs \\ %{}) do
    code = Faker.Lorem.characters(6..10) |> to_string() |> String.replace(~r/[^a-zA-Z0-9]/, "")

    # 80% partial objects, 20% IDs only
    has_objects = Faker.Util.pick([true, true, true, true, false])

    # 50% extended invites with counts
    has_counts = Faker.Util.pick([true, false])

    # 10% target invites (stream/embedded app)
    has_target = Faker.Util.pick([true] ++ List.duplicate(false, 9))

    # 5% event invites
    has_event = Faker.Util.pick([true] ++ List.duplicate(false, 19))

    guild_id_value = generate_snowflake()
    channel_id_value = generate_snowflake()

    defaults = %{
      code: code,
      guild:
        if has_objects do
          %{
            id: guild_id_value,
            name: Faker.Company.name(),
            splash: nil,
            banner: nil,
            description: nil,
            icon: nil,
            features: [],
            verification_level: 0,
            vanity_url_code: nil
          }
        else
          nil
        end,
      guild_id: if(not has_objects, do: guild_id_value, else: nil),
      channel:
        if has_objects do
          %{
            id: channel_id_value,
            name: Faker.Lorem.word(),
            type: Faker.Util.pick([0, 2, 5, 13, 15])
          }
        else
          nil
        end,
      channel_id: if(not has_objects, do: channel_id_value, else: nil),
      inviter: %{
        id: generate_snowflake(),
        username: Faker.Internet.user_name(),
        discriminator: "0",
        avatar: nil
      },
      target_user:
        if has_target do
          %{
            id: generate_snowflake(),
            username: Faker.Internet.user_name(),
            discriminator: "0",
            avatar: nil
          }
        else
          nil
        end,
      target_type: if(has_target, do: Faker.Util.pick([1, 2]), else: nil),
      target_user_type: nil,
      approximate_presence_count: if(has_counts, do: Faker.random_between(10, 1000), else: nil),
      approximate_member_count: if(has_counts, do: Faker.random_between(100, 10_000), else: nil),
      uses: Faker.random_between(0, 100),
      max_uses: Faker.Util.pick([0, 10, 25, 50, 100]),
      max_age: Faker.Util.pick([0, 1800, 3600, 86_400, 604_800]),
      temporary: Faker.Util.pick([true, false, false]),
      created_at: Faker.DateTime.backward(30) |> DateTime.to_iso8601(),
      expires_at:
        if(Faker.Util.pick([true, false, false]),
          do: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
          else: nil
        ),
      stage_instance: nil,
      guild_scheduled_event:
        if has_event do
          %{
            id: generate_snowflake(),
            name: Faker.Lorem.sentence(1..5),
            description: Faker.Lorem.sentence(5..20)
          }
        else
          nil
        end
    }

    struct(Nostrum.Struct.Invite, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord application command struct.

  ## Options

  - `:id` - Command ID (defaults to generated snowflake)
  - `:application_id` - Application ID (defaults to generated snowflake)
  - `:name` - Command name (defaults to generated name)
  - `:description` - Command description (defaults to generated description)
  - `:options` - Command options (defaults to empty list)
  - `:type` - Command type (defaults to 1 for CHAT_INPUT)

  ## Examples

      iex> command = application_command(%{name: "test"})
      iex> command.name
      "test"
  """
  def application_command(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      application_id: generate_snowflake(),
      name: Faker.Lorem.word(),
      description: Faker.Lorem.sentence(3..20),
      options: [],
      type: 1
    }

    merge_attrs(defaults, attrs)
  end

  @doc """
  Generates interaction data for application commands.

  ## Options

  - `:id` - Command ID (defaults to generated snowflake)
  - `:name` - Command name (defaults to generated name)
  - `:type` - Command type (defaults to 1)
  - `:options` - Command options (defaults to empty list)
  - `:resolved` - Resolved data (defaults to nil)

  ## Examples

      iex> data = interaction_data(%{name: "hello"})
      iex> data.name
      "hello"
  """
  def interaction_data(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      name: Faker.Lorem.word(),
      type: 1,
      options: [],
      resolved: nil
    }

    merge_attrs(defaults, attrs)
  end

  @doc """
  Generates a command option for application commands.

  ## Options

  - `:name` - Option name (defaults to generated name)
  - `:type` - Option type (3=string, 4=integer, 5=boolean, etc.)
  - `:value` - Option value (defaults based on type)

  ## Examples

      iex> opt = option(%{name: "message", type: 3, value: "Hello"})
      iex> opt.name
      "message"
      iex> opt.type
      3
      iex> opt.value
      "Hello"
  """
  def option(attrs \\ %{}) do
    option_type = Map.get(attrs, :type, 3)

    default_value =
      case option_type do
        # string
        3 -> Faker.Lorem.sentence(1..10)
        # integer
        4 -> Faker.random_between(1, 100)
        # boolean
        5 -> Faker.Util.pick([true, false])
        # user
        6 -> user()
        # channel
        7 -> channel()
        # role
        8 -> role()
        # number
        10 -> Faker.random_between(1, 100) / 10
        _ -> nil
      end

    defaults = %{
      name: Faker.Lorem.word(),
      type: option_type,
      value: default_value
    }

    merge_attrs(defaults, attrs)
  end

  @doc """
  Generates a Discord permission overwrite struct.

  ## Options

  - `:id` - Target ID (user or role ID) (defaults to generated snowflake)
  - `:type` - Overwrite type (0=role, 1=member) (defaults to 0)
  - `:allow` - Allowed permissions bitfield (defaults to 0)
  - `:deny` - Denied permissions bitfield (defaults to 0)

  ## Examples

      iex> overwrite = permission_overwrite(%{type: 1, allow: 1024})
      iex> overwrite.type
      1
      iex> overwrite.allow
      1024
  """
  def permission_overwrite(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      type: Faker.Util.pick([0, 1]),
      allow: Faker.random_between(0, 2_147_483_647),
      deny: Faker.random_between(0, 2_147_483_647)
    }

    struct(Nostrum.Struct.Overwrite, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord voice state struct.

  ## Options

  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:channel_id` - Voice channel ID (defaults to generated snowflake)
  - `:user_id` - User ID (defaults to generated snowflake)
  - `:session_id` - Voice session ID (defaults to generated UUID)
  - `:deaf` - Whether user is deafened (defaults to false)
  - `:mute` - Whether user is muted (defaults to false)
  - `:self_deaf` - Whether user is self-deafened (defaults to false)
  - `:self_mute` - Whether user is self-muted (defaults to false)
  - `:suppress` - Whether user is suppressed (defaults to false)

  ## Examples

      iex> voice_state = voice_state(%{deaf: true})
      iex> voice_state.deaf
      true
  """
  def voice_state(attrs \\ %{}) do
    voice_user = user()

    # 80% guild voice, 20% DM voice (Discord supports DM voice calls)
    has_guild = Faker.Util.pick([true, true, true, true, false])
    guild_id_value = if has_guild, do: generate_snowflake(), else: nil

    member_value =
      if has_guild do
        %Nostrum.Struct.Guild.Member{
          user_id: voice_user.id,
          nick:
            if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
          roles: [],
          joined_at: Faker.DateTime.backward(365),
          premium_since:
            if(Faker.Util.pick([true, false, false, false]),
              do: Faker.DateTime.backward(30),
              else: nil
            ),
          communication_disabled_until: nil,
          deaf: false,
          mute: false,
          pending: false,
          flags: 0
        }
      else
        nil
      end

    # Support disconnection pattern (10% of voice states)
    channel_id_value =
      if Faker.Util.pick(List.duplicate(true, 9) ++ [false]) do
        generate_snowflake()
      else
        nil
      end

    defaults = %{
      guild_id: guild_id_value,
      channel_id: channel_id_value,
      user_id: voice_user.id,
      member: member_value,
      session_id: Faker.UUID.v4(),
      deaf: false,
      mute: false,
      self_deaf: Faker.Util.pick([true, false, false]),
      self_mute: Faker.Util.pick([true, false, false]),
      self_stream: Faker.Util.pick([true] ++ List.duplicate(false, 9)),
      self_video: Faker.Util.pick([true, false, false, false]),
      suppress: false,
      request_to_speak_timestamp: nil
    }

    struct(Nostrum.Struct.Event.VoiceState, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord message attachment struct.

  ## Options

  - `:id` - Attachment ID (defaults to generated snowflake)
  - `:filename` - File name (defaults to generated filename)
  - `:size` - File size in bytes (defaults to random size)
  - `:url` - Attachment URL (defaults to generated URL)
  - `:proxy_url` - Proxy URL (defaults to generated URL)
  - `:height` - Image height in pixels (defaults to random for images)
  - `:width` - Image width in pixels (defaults to random for images)
  - `:content_type` - MIME type (defaults to based on filename)

  ## Examples

      iex> attachment = message_attachment(%{filename: "image.png"})
      iex> attachment.filename
      "image.png"
  """
  def message_attachment(attrs \\ %{}) do
    extension = Faker.Util.pick(["png", "jpg", "gif", "pdf", "txt"])
    filename = "#{Faker.Lorem.word()}.#{extension}"

    defaults = %{
      id: generate_snowflake(),
      filename: filename,
      size: Faker.random_between(1024, 8_388_608),
      url:
        "https://cdn.discordapp.com/attachments/#{generate_snowflake()}/#{generate_snowflake()}/#{filename}",
      proxy_url:
        "https://media.discordapp.net/attachments/#{generate_snowflake()}/#{generate_snowflake()}/#{filename}",
      height:
        if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1080), else: nil),
      width:
        if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1920), else: nil)
    }

    struct(Nostrum.Struct.Message.Attachment, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord message reaction struct.

  ## Options

  - `:emoji` - Emoji struct (defaults to generated emoji)
  - `:count` - Reaction count (defaults to random 1-10)
  - `:me` - Whether current user reacted (defaults to false)
  - `:user_id` - User ID who reacted (defaults to generated snowflake)
  - `:message_id` - Message ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)

  ## Examples

      iex> reaction = message_reaction(%{count: 5})
      iex> reaction.count
      5
  """
  def message_reaction(attrs \\ %{}) do
    # Generate either unicode or custom emoji
    emoji_struct =
      if Faker.Util.pick([true, false]) do
        # Unicode emoji (id is nil)
        struct(Nostrum.Struct.Emoji, %{
          id: nil,
          name: Faker.Util.pick(["👍", "👎", "❤️", "😂", "😢", "🔥"]),
          animated: false,
          managed: false,
          require_colons: false,
          roles: [],
          user: nil
        })
      else
        # Custom emoji
        struct(Nostrum.Struct.Emoji, %{
          id: generate_snowflake(),
          name: Faker.Lorem.word(),
          animated: Faker.Util.pick([true, false]),
          managed: false,
          require_colons: true,
          roles: [],
          user: nil
        })
      end

    defaults = %{
      emoji: emoji_struct,
      count: Faker.random_between(1, 10),
      me: Faker.Util.pick([true, false])
    }

    struct(Nostrum.Struct.Message.Reaction, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord guild member struct (alias for member/1).

  This is an alias for the member/1 function to match the test naming convention.
  """
  def guild_member(attrs \\ %{}) do
    member(attrs)
  end

  @doc """
  Generates a Discord sticker struct.

  ## Options

  - `:id` - Sticker ID (defaults to generated snowflake)
  - `:name` - Sticker name (defaults to generated name)
  - `:description` - Sticker description (defaults to generated sentence)
  - `:tags` - Sticker tags (defaults to generated tags)
  - `:type` - Sticker type (defaults to 1 for guild sticker)
  - `:format_type` - Format type (1=PNG, 2=APNG, 3=Lottie) (defaults to 1)
  - `:available` - Whether sticker is available (defaults to true)
  - `:guild_id` - Guild ID (defaults to generated snowflake)

  ## Examples

      iex> sticker = sticker(%{name: "custom_sticker"})
      iex> sticker.name
      "custom_sticker"
  """
  def sticker(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      name: Faker.Lorem.word(),
      description: Faker.Lorem.sentence(3..10),
      tags: Enum.join([Faker.Lorem.word(), Faker.Lorem.word()], ","),
      # type should be atom, not integer
      type: Faker.Util.pick([:standard, :guild]),
      # format_type should be atom, not integer
      format_type: Faker.Util.pick([:png, :apng, :lottie, :gif]),
      available: true,
      guild_id: generate_snowflake()
    }

    struct(Nostrum.Struct.Sticker, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord typing indicator struct.

  ## Options

  - `:user_id` - User ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:timestamp` - Timestamp (defaults to current unix timestamp)

  ## Examples

      iex> typing = typing_indicator(%{user_id: 123456})
      iex> typing.user_id
      123456
  """
  def typing_indicator(attrs \\ %{}) do
    defaults = %{
      user_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake(),
      timestamp: DateTime.utc_now(),
      member: nil
    }

    struct(Nostrum.Struct.Event.TypingStart, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord ChannelPinsUpdate event struct.

  ## Options

  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:last_pin_timestamp` - Timestamp of last pinned message (defaults to current datetime)

  ## Examples

      iex> pins = channel_pins_update(%{channel_id: 123456})
      iex> pins.channel_id
      123456
  """
  def channel_pins_update(attrs \\ %{}) do
    defaults = %{
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake(),
      last_pin_timestamp: DateTime.utc_now()
    }

    struct(Nostrum.Struct.Event.ChannelPinsUpdate, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord MessageDelete event struct.

  ## Options

  - `:id` - Message ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)

  ## Examples

      iex> event = message_delete_event(%{id: 123456})
      iex> event.id
      123456
  """
  def message_delete_event(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake()
    }

    struct(Nostrum.Struct.Event.MessageDelete, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord MessageDeleteBulk event struct.

  ## Options

  - `:ids` - List of message IDs (defaults to list of generated snowflakes)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)

  ## Examples

      iex> event = message_delete_bulk_event(%{ids: [123, 456]})
      iex> event.ids
      [123, 456]
  """
  def message_delete_bulk_event(attrs \\ %{}) do
    defaults = %{
      ids: Enum.map(1..Faker.random_between(2, 10), fn _ -> generate_snowflake() end),
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake()
    }

    struct(Nostrum.Struct.Event.MessageDeleteBulk, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord UnavailableGuild struct.

  ## Options

  - `:id` - Guild ID (defaults to generated snowflake)
  - `:unavailable` - Whether guild is unavailable (defaults to true)

  ## Examples

      iex> unavailable = unavailable_guild(%{id: 123456})
      iex> unavailable.id
      123456
      iex> unavailable.unavailable
      true
  """
  def unavailable_guild(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      unavailable: true
    }

    struct(Nostrum.Struct.Guild.UnavailableGuild, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord thread channel struct.

  ## Options

  - `:id` - Thread ID (defaults to generated snowflake)
  - `:type` - Channel type (defaults to 11 for public thread)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:parent_id` - Parent channel ID (defaults to generated snowflake)
  - `:name` - Thread name (defaults to generated name)
  - `:owner_id` - Thread creator user ID (defaults to generated snowflake)
  - `:message_count` - Approximate message count (defaults to random 0-100)
  - `:member_count` - Approximate member count (defaults to random 1-50)

  ## Examples

      iex> thread = thread(%{name: "Discussion Thread"})
      iex> thread.name
      "Discussion Thread"
      iex> thread.type
      11
  """
  def thread(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      type: 11,
      guild_id: generate_snowflake(),
      parent_id: generate_snowflake(),
      name: "#{Faker.Lorem.word()} Thread",
      owner_id: generate_snowflake(),
      message_count: Faker.random_between(0, 100),
      member_count: Faker.random_between(1, 50),
      thread_metadata: %{
        archived: false,
        auto_archive_duration: 1440,
        archive_timestamp: Faker.DateTime.backward(1) |> DateTime.to_iso8601(),
        locked: false
      }
    }

    struct(Nostrum.Struct.Channel, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord MessageReactionAdd event struct.

  ## Options

  - `:user_id` - User ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:message_id` - Message ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:emoji` - Emoji map (defaults to unicode emoji)

  ## Examples

      iex> event = message_reaction_add_event(%{user_id: 123})
      iex> event.user_id
      123
  """
  def message_reaction_add_event(attrs \\ %{}) do
    defaults = %{
      user_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      message_id: generate_snowflake(),
      guild_id: generate_snowflake(),
      emoji: %{
        id: nil,
        name: Faker.Util.pick(["👍", "❤️", "😂", "🔥"]),
        animated: false
      },
      member: nil
    }

    struct(Nostrum.Struct.Event.MessageReactionAdd, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord MessageReactionRemove event struct.

  ## Options

  - `:user_id` - User ID (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:message_id` - Message ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:emoji` - Emoji map (defaults to unicode emoji)

  ## Examples

      iex> event = message_reaction_remove_event(%{user_id: 123})
      iex> event.user_id
      123
  """
  def message_reaction_remove_event(attrs \\ %{}) do
    defaults = %{
      user_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      message_id: generate_snowflake(),
      guild_id: generate_snowflake(),
      emoji: %{
        id: nil,
        name: Faker.Util.pick(["👍", "❤️", "😂", "🔥"]),
        animated: false
      }
    }

    struct(Nostrum.Struct.Event.MessageReactionRemove, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord MessageReactionRemoveAll event struct.

  ## Options

  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:message_id` - Message ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)

  ## Examples

      iex> event = message_reaction_remove_all_event(%{message_id: 123})
      iex> event.message_id
      123
  """
  def message_reaction_remove_all_event(attrs \\ %{}) do
    defaults = %{
      channel_id: generate_snowflake(),
      message_id: generate_snowflake(),
      guild_id: generate_snowflake()
    }

    struct(Nostrum.Struct.Event.MessageReactionRemoveAll, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord Ready event struct.

  ## Options

  - `:user` - Bot user struct (defaults to generated user)
  - `:guilds` - List of unavailable guilds (defaults to empty list)
  - `:session_id` - Session ID (defaults to generated UUID)
  - `:application` - Application data (defaults to basic map)

  ## Examples

      iex> event = ready_event(%{session_id: "abc123"})
      iex> event.session_id
      "abc123"
  """
  def ready_event(attrs \\ %{}) do
    defaults = %{
      user: user(%{bot: true}),
      guilds: [],
      session_id: Faker.UUID.v4(),
      application: %{
        id: generate_snowflake(),
        flags: 0
      },
      shard: nil
    }

    struct(Nostrum.Struct.Event.Ready, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord ThreadMember struct.

  ## Options

  - `:id` - Thread ID (defaults to generated snowflake)
  - `:user_id` - User ID (defaults to generated snowflake)
  - `:join_timestamp` - Join timestamp (defaults to recent datetime)
  - `:flags` - Thread member flags (defaults to 0)

  ## Examples

      iex> thread_member = thread_member(%{user_id: 123})
      iex> thread_member.user_id
      123
  """
  def thread_member(attrs \\ %{}) do
    # 20% GUILD_CREATE events (id and user_id omitted)
    is_guild_create = Faker.Util.pick([true] ++ List.duplicate(false, 4))

    defaults = %{
      id: if(is_guild_create, do: nil, else: generate_snowflake()),
      user_id: if(is_guild_create, do: nil, else: generate_snowflake()),
      join_timestamp: Faker.DateTime.backward(7),
      flags: Faker.Util.pick([0, 0, 1, 3]),
      guild_id:
        if(Faker.Util.pick(List.duplicate(true, 9) ++ [false]),
          do: generate_snowflake(),
          else: nil
        )
    }

    struct(Nostrum.Struct.ThreadMember, merge_attrs(defaults, attrs))
  end

  # Private helper functions

  @doc """
  Generates a Discord AutoModerationRule struct.

  ## Options

  - `:id` - Rule ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:name` - Rule name (defaults to random name)
  - `:creator_id` - Creator user ID (defaults to generated snowflake)
  - `:event_type` - Event type (defaults to 1 = MESSAGE_SEND)
  - `:trigger_type` - Trigger type (defaults to 1 = KEYWORD)
  - `:trigger_metadata` - Trigger metadata map (defaults to keyword list)
  - `:actions` - Actions to execute (defaults to list with block action)
  - `:enabled` - Whether rule is enabled (defaults to true)
  - `:exempt_roles` - Exempt role IDs (defaults to empty list)
  - `:exempt_channels` - Exempt channel IDs (defaults to empty list)

  ## Examples

      iex> rule = auto_moderation_rule(%{name: "No Spam"})
      iex> rule.name
      "No Spam"
  """
  def auto_moderation_rule(attrs \\ %{}) do
    defaults = %{
      id: generate_snowflake(),
      guild_id: generate_snowflake(),
      name: Faker.Lorem.words(2..3) |> Enum.join(" "),
      creator_id: generate_snowflake(),
      event_type: 1,
      trigger_type: 1,
      trigger_metadata: %{
        keyword_filter: ["spam", "badword"]
      },
      actions: [
        %{
          type: 1,
          metadata: %{
            channel_id: generate_snowflake()
          }
        }
      ],
      enabled: true,
      exempt_roles: [],
      exempt_channels: []
    }

    struct(Nostrum.Struct.AutoModerationRule, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord AutoModerationRuleExecute event struct.

  ## Options

  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:action` - Action that was executed (defaults to block action)
  - `:rule_id` - Rule ID (defaults to generated snowflake)
  - `:rule_trigger_type` - Rule trigger type (defaults to 1 = KEYWORD)
  - `:user_id` - User ID who triggered rule (defaults to generated snowflake)
  - `:channel_id` - Channel ID (defaults to generated snowflake)
  - `:message_id` - Message ID (defaults to generated snowflake)
  - `:alert_system_message_id` - Alert message ID (defaults to nil)
  - `:content` - Content that triggered rule (defaults to sample text)
  - `:matched_keyword` - Matched keyword (defaults to "spam")
  - `:matched_content` - Matched content substring (defaults to "spam")

  ## Examples

      iex> execute = auto_moderation_rule_execute(%{user_id: 123})
      iex> execute.user_id
      123
  """
  def auto_moderation_rule_execute(attrs \\ %{}) do
    defaults = %{
      guild_id: generate_snowflake(),
      action: %{
        type: 1,
        metadata: %{
          channel_id: generate_snowflake()
        }
      },
      rule_id: generate_snowflake(),
      rule_trigger_type: 1,
      user_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      message_id: generate_snowflake(),
      alert_system_message_id: nil,
      content: "This message contains spam content",
      matched_keyword: "spam",
      matched_content: "spam"
    }

    struct(Nostrum.Struct.Event.AutoModerationRuleExecute, merge_attrs(defaults, attrs))
  end

  # Private helper functions

  defp merge_attrs(defaults, overrides) when is_map(overrides) do
    Map.merge(defaults, overrides)
  end

  defp merge_attrs(defaults, _), do: defaults

  defp rgb_to_int({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    (r <<< 16) + (g <<< 8) + b
  end

  defp rgb_to_int(_), do: 0
end
