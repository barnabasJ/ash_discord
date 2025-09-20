defmodule TestHelper do
  @moduledoc """
  Test helper utilities for AshDiscord test suite.
  """

  import Mimic

  @doc """
  Set up mocks for Discord API and other external services.
  """
  def setup_mocks do
    # Copy modules for mocking
    copy(Nostrum.Api.Guild)
    copy(Nostrum.Api.User)
    copy(Nostrum.Api.Message)
    copy(Nostrum.Api.Channel)
    copy(Nostrum.Api.Interaction)

    # Mock Discord API calls with default stubs
    stub(Nostrum.Api.Guild, :get, fn guild_id ->
      {:ok,
       %Nostrum.Struct.Guild{
         id: guild_id,
         name: "Test Guild #{guild_id}",
         description: "A test guild"
       }}
    end)

    stub(Nostrum.Api.User, :get, fn user_id ->
      {:ok,
       %Nostrum.Struct.User{
         id: user_id,
         username: "testuser#{user_id}",
         discriminator: "1234"
       }}
    end)

    stub(Nostrum.Api.Message, :get, fn channel_id, message_id ->
      {:ok,
       %Nostrum.Struct.Message{
         id: message_id,
         channel_id: channel_id,
         content: "Test message content",
         timestamp: DateTime.utc_now(),
         author: %Nostrum.Struct.User{
           id: 123_456_789,
           username: "testuser",
           discriminator: "1234"
         }
       }}
    end)

    stub(Nostrum.Api.Channel, :get, fn channel_id ->
      {:ok,
       %Nostrum.Struct.Channel{
         id: channel_id,
         name: "test-channel",
         type: 0
       }}
    end)

    stub(Nostrum.Api.Interaction, :create_response, fn _id, _token, response ->
      {:ok, response}
    end)

    :ok
  end
end
