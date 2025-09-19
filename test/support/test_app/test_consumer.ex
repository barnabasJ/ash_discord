defmodule TestApp.TestConsumer do
  @moduledoc """
  Test consumer for validating AshDiscord.Consumer using macro functionality.
  """

  use AshDiscord.Consumer
  
  # Note: The DSL configuration needs to be set up differently
  # For now, using default configuration

  @doc """
  Override message create handling for testing.
  """
  @impl true
  def handle_message_create(message) do
    # Create message using from_discord pattern
    TestApp.Discord.Message.from_discord!(%{
      discord_id: message.id
    })

    # Call parent implementation for any additional processing
    super(message)
  end

  @doc """
  Override guild create handling for testing.
  """
  @impl true
  def handle_guild_create(guild) do
    # Create guild using from_discord pattern
    TestApp.Discord.Guild.from_discord!(%{
      discord_id: guild.id
    })

    super(guild)
  end

  @doc """
  Override interaction create for Discord command testing.
  """
  @impl true
  def handle_interaction_create(interaction) do
    # Let parent handle routing to actions
    result = super(interaction)

    # Log for testing verification
    Process.put(:last_interaction, interaction)
    Process.put(:last_interaction_result, result)

    result
  end

  @doc """
  Override application command handling for testing.
  """
  @impl true
  def handle_application_command(interaction) do
    # Route through AshDiscord system
    result = super(interaction)

    # Store for test verification  
    Process.put(:last_command, interaction)
    Process.put(:last_command_result, result)

    result
  end
end
