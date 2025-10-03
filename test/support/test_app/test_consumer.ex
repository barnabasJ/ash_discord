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

  This callback gets called by the handler when INTERACTION_CREATE event is received.
  The signature is: handle_interaction_create(payload, ws_state) - 2 args
  But we call the handler with (consumer, payload, ws_state) - 3 args
  """
  def handle_interaction_create(interaction, ws_state) do
    # Log for testing verification before calling handler
    Process.put(:last_interaction, interaction)

    result = AshDiscord.Consumer.Handler.Interaction.create(__MODULE__, interaction, ws_state)

    Process.put(:last_interaction_result, result)

    result
  end
end
