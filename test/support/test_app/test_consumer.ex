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
  The signature is: handle_interaction_create(payload, ws_state, context) - 3 args
  """
  @impl AshDiscord.Consumer
  def handle_interaction_create(interaction, ws_state, context) do
    # Log for testing verification before calling handler
    Process.put(:last_interaction, interaction)

    result = AshDiscord.Consumer.Handler.Interaction.create(interaction, ws_state, context)

    Process.put(:last_interaction_result, result)

    result
  end
end
