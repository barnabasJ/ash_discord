defmodule TestApp.Discord do
  @moduledoc """
  Test Discord domain for validating AshDiscord functionality.
  """

  use Ash.Domain,
    extensions: [AshDiscord]

  resources do
    resource TestApp.Discord.Guild do
      define(:guild_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Message do
      define(:message_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.User do
      define(:user_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.GuildMember do
      define(:guild_member_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Role do
      define(:role_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Emoji do
      define(:emoji_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Channel do
      define(:channel_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.VoiceState do
      define(:voice_state_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Webhook do
      define(:webhook_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Invite do
      define(:invite_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.MessageAttachment do
      define(:message_attachment_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.MessageReaction do
      define(:message_reaction_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.TypingIndicator do
      define(:typing_indicator_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Sticker do
      define(:sticker_from_discord, action: :from_discord)
    end

    resource TestApp.Discord.Interaction do
      define(:interaction_from_discord, action: :from_discord)
    end
  end

  discord do
    # Basic test command without options
    command :hello, TestApp.Discord.Message, :hello do
      description("A simple hello command")
    end

    # Basic ping command for integration tests
    command :ping, TestApp.Discord.Message, :hello do
      description("Test ping command")
    end

    # Echo command with options for integration tests  
    command :echo, TestApp.Discord.Message, :create do
      description("Echo back a message")

      option(:message, :string, description: "Message to echo", required: true)
    end

    # Command with auto-detected options from action
    command :create_message, TestApp.Discord.Message, :create do
      description("Create a message with content")
      # Options auto-detected from action inputs
    end

    # Command with manual options override  
    command :search, TestApp.Discord.Message, :search do
      description("Search messages")

      option(:query, :string, description: "Search query", required: true)
      option(:limit, :integer, description: "Number of results", required: false)
    end

    # Command that tests complex option types
    command :configure, TestApp.Discord.Guild, :configure do
      description("Configure Discord settings")

      option(:setting, :string, description: "Setting to configure", required: true)
      option(:enabled, :boolean, description: "Enable or disable", required: true)
    end

    # Admin command for testing command filtering
    command :admin_ban, TestApp.Discord.User, :ban do
      description("Ban a user from the server (admin only)")

      option(:user, :string, description: "User to ban", required: true)
      option(:reason, :string, description: "Reason for ban", required: false)
    end
  end
end
