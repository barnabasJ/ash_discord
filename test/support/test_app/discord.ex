defmodule TestApp.Discord do
  @moduledoc """
  Test Discord domain for validating AshDiscord functionality.
  """

  use Ash.Domain,
    extensions: [AshDiscord]

  resources do
    resource TestApp.Discord.Guild
    resource TestApp.Discord.Message
    resource TestApp.Discord.User
    resource TestApp.Discord.GuildMember
  end

  discord do
    # Basic test command without options
    command :hello, TestApp.Discord.Message, :hello do
      description "A simple hello command"
    end

    # Basic ping command for integration tests
    command :ping, TestApp.Discord.Message, :hello do
      description "Test ping command"
    end

    # Echo command with options for integration tests  
    command :echo, TestApp.Discord.Message, :create do
      description "Echo back a message"

      option :message, :string, description: "Message to echo", required: true
    end

    # Command with auto-detected options from action
    command :create_message, TestApp.Discord.Message, :create do
      description "Create a message with content"
      # Options auto-detected from action inputs
    end

    # Command with manual options override  
    command :search, TestApp.Discord.Message, :search do
      description "Search messages"

      option :query, :string, description: "Search query", required: true
      option :limit, :integer, description: "Number of results", required: false
    end

    # Command that tests complex option types
    command :configure, TestApp.Discord.Guild, :configure do
      description "Configure Discord settings"

      option :setting, :string, description: "Setting to configure", required: true
      option :enabled, :boolean, description: "Enable or disable", required: true
    end

    # Admin command for testing command filtering
    command :admin_ban, TestApp.Discord.User, :ban do
      description "Ban a user from the server (admin only)"

      option :user, :string, description: "User to ban", required: true
      option :reason, :string, description: "Reason for ban", required: false
    end
  end

  # Domain interface methods for testing
  def from_discord_guild(attrs), do: TestApp.Discord.Guild.from_discord(attrs)
  def from_discord_message(attrs), do: TestApp.Discord.Message.from_discord(attrs) 
  def from_discord_user(attrs), do: TestApp.Discord.User.from_discord(attrs)

  # Generic create method with resource and action
  def create(resource, action, attrs) do
    Ash.create(resource, attrs, action: action, domain: __MODULE__)
  end
end
