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
      bitrate: 64000,
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

    defaults = %{
      id: generate_snowflake(),
      channel_id: generate_snowflake(),
      guild_id: nil,
      author: author_user,
      content: Faker.Lorem.sentence(3..50),
      timestamp: Faker.DateTime.backward(30) |> DateTime.to_iso8601(),
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

    # Add edited timestamp 25% of the time
    final_result =
      if Faker.Util.pick([true, false, false, false]) do
        edited_time =
          result.timestamp
          |> DateTime.from_iso8601()
          |> elem(1)
          |> DateTime.add(Faker.random_between(60, 7200), :second)
          |> DateTime.to_iso8601()

        Map.put(result, :edited_timestamp, edited_time)
      else
        result
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

    defaults = %{
      id: generate_snowflake(),
      application_id: generate_snowflake(),
      type: 2,
      data: %{
        name: Faker.Util.pick(["hello", "help", "ping", "info"]),
        options: []
      },
      guild_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      member: %{
        user: interaction_user
      },
      user: interaction_user,
      token: "#{Faker.UUID.v4()}#{Faker.UUID.v4()}",
      version: 1
    }

    struct(Nostrum.Struct.Interaction, merge_attrs(defaults, attrs))
  end

  @doc """
  Generates a Discord guild member struct.

  ## Options

  - `:user_id` - User ID (defaults to generated snowflake)
  - `:guild_id` - Guild ID (defaults to generated snowflake)
  - `:user` - User struct (defaults to generated user)
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
      user: member_user,
      nick: if(Faker.Util.pick([true, false, false]), do: Faker.Person.first_name(), else: nil),
      roles: [],
      joined_at: Faker.DateTime.backward(365) |> DateTime.to_iso8601(),
      premium_since: nil,
      deaf: false,
      mute: false,
      pending: false
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
      type: 1,
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

    defaults = %{
      code: code,
      guild: guild(),
      channel: channel(),
      inviter: user(),
      target_user: nil,
      expires_at: Faker.DateTime.forward(7) |> DateTime.to_iso8601(),
      max_uses: 0,
      uses: 0
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
    defaults = %{
      guild_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      user_id: generate_snowflake(),
      session_id: Faker.UUID.v4(),
      deaf: false,
      mute: false,
      self_deaf: false,
      self_mute: false,
      self_stream: false,
      self_video: false,
      suppress: false
    }

    struct(Nostrum.Struct.VoiceState, merge_attrs(defaults, attrs))
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
        if(extension in ["png", "jpg", "gif"], do: Faker.random_between(100, 1920), else: nil),
      content_type:
        case extension do
          "png" -> "image/png"
          "jpg" -> "image/jpeg"
          "gif" -> "image/gif"
          "pdf" -> "application/pdf"
          "txt" -> "text/plain"
          _ -> nil
        end
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
    emoji_data =
      if Faker.Util.pick([true, false]) do
        # Unicode emoji
        %{id: nil, name: Faker.Util.pick(["👍", "👎", "❤️", "😂", "😢", "🔥"]), animated: false}
      else
        # Custom emoji
        %{
          id: generate_snowflake(),
          name: Faker.Lorem.word(),
          animated: Faker.Util.pick([true, false])
        }
      end

    defaults = %{
      emoji: emoji_data,
      count: Faker.random_between(1, 10),
      me: Faker.Util.pick([true, false]),
      user_id: generate_snowflake(),
      message_id: generate_snowflake(),
      channel_id: generate_snowflake(),
      guild_id: generate_snowflake()
    }

    # Note: Nostrum doesn't have a specific Reaction struct, so we return a map
    merge_attrs(defaults, attrs)
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
      type: 1,
      format_type: Faker.Util.pick([1, 2, 3]),
      available: true,
      guild_id: generate_snowflake()
    }

    # Note: Nostrum doesn't have a specific Sticker struct, so we return a map
    merge_attrs(defaults, attrs)
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
      timestamp: System.system_time(:second)
    }

    # Note: Nostrum doesn't have a specific TypingIndicator struct, so we return a map
    merge_attrs(defaults, attrs)
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
