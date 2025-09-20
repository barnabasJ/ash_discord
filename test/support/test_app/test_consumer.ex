defmodule TestApp.TestConsumer do
  @moduledoc """
  Test consumer for validating AshDiscord.Consumer using macro functionality.
  """

  use AshDiscord.Consumer

  ash_discord_consumer do
    domains([TestApp.Discord])
    user_resource(TestApp.Discord.User)
    guild_resource(TestApp.Discord.Guild)
    guild_member_resource(TestApp.Discord.Guild)
    message_resource(TestApp.Discord.Message)
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
