defmodule TestApp.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TestApp.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
  end

  setup _ do
    # Clean up ETS tables between tests
    on_exit(fn ->
      # Clear all data from test resources that have destroy actions
      TestApp.Discord.User
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Guild
      |> Ash.bulk_destroy!(:destroy, %{})

      # GuildMember doesn't have a destroy action - skip it

      TestApp.Discord.Role
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Channel
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Message
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Emoji
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.VoiceState
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Webhook
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Invite
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.MessageAttachment
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.MessageReaction
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.TypingIndicator
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Sticker
      |> Ash.bulk_destroy!(:destroy, %{})

      TestApp.Discord.Interaction
      |> Ash.bulk_destroy!(:destroy, %{})
    end)

    :ok
  end
end
