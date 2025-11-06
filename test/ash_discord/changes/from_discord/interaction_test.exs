defmodule AshDiscord.Changes.FromDiscord.InteractionTest do
  @moduledoc """
  Comprehensive tests for Interaction entity from_discord transformation.

  Tests struct-first pattern and upsert behavior.

  Note: Interactions are ephemeral and cannot be fetched from Discord API,
  so API fallback pattern is not applicable.
  """

  use TestApp.DataCase, async: true
  use Mimic

  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    @tag :fixed
    test "creates interaction from discord struct with all attributes" do
      guild_id = 111_222_333
      channel_id = 444_555_666
      user_id = 777_888_999

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      interaction_struct =
        interaction(%{
          id: 123_456_789,
          application_id: 987_654_321,
          type: 2,
          data: %{
            id: 555_666_777,
            name: "test_command",
            type: 1
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "test_user"},
            nick: "TestNick"
          },
          user: nil,
          token: "interaction_token_abc123",
          version: 1,
          locale: "en-US",
          guild_locale: "en-US"
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:guild, :channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.application_id == interaction_struct.application_id
      assert created.type == interaction_struct.type
      assert created.token == interaction_struct.token
      assert created.version == interaction_struct.version
      assert created.locale == interaction_struct.locale
      assert created.guild_locale == interaction_struct.guild_locale
      assert created.guild.discord_id == guild_id
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles slash command interaction" do
      guild_id = 444_555_666
      channel_id = 777_888_999
      user_id = 333_444_555

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "slash_user"})}
      end)

      interaction_struct =
        interaction(%{
          id: 987_654_321,
          application_id: 123_456_789,
          type: 2,
          data: %{
            id: 111_222_333,
            name: "ping",
            type: 1,
            options: []
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "slash_user"},
            nick: nil
          },
          token: "slash_token_def456",
          version: 1
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:guild, :channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.type == 2
      assert created.guild.discord_id == guild_id
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles message component interaction" do
      guild_id = 333_444_555
      channel_id = 666_777_888
      user_id = 999_111_222

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "button_user"})}
      end)

      interaction_struct =
        interaction(%{
          id: 111_222_333,
          application_id: 777_888_999,
          type: 3,
          data: %{
            custom_id: "button_click",
            component_type: 2
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "button_user"},
            nick: "ButtonClicker"
          },
          token: "component_token_ghi789",
          version: 1,
          message: %{
            id: 222_333_444,
            content: "Click the button!"
          }
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:guild, :channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.type == 3
      assert created.guild.discord_id == guild_id
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles modal submit interaction" do
      guild_id = 555_666_777
      channel_id = 111_222_333
      user_id = 222_333_444

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "modal_user"})}
      end)

      interaction_struct =
        interaction(%{
          id: 444_555_666,
          application_id: 888_999_111,
          type: 5,
          data: %{
            custom_id: "modal_submit",
            components: [
              %{
                type: 1,
                components: [
                  %{
                    type: 4,
                    custom_id: "text_input",
                    value: "User input text"
                  }
                ]
              }
            ]
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "modal_user"},
            nick: nil
          },
          token: "modal_token_jkl012",
          version: 1
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:guild, :channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.type == 5
      assert created.guild.discord_id == guild_id
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles DM interaction without guild" do
      channel_id = 777_888_999
      user_id = 111_222_333

      Mimic.stub(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, guild_id: nil, name: "dm-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "dm_user"})}
      end)

      interaction_struct =
        interaction(%{
          id: 666_777_888,
          application_id: 999_111_222,
          type: 2,
          data: %{
            id: 333_444_555,
            name: "dm_command",
            type: 1
          },
          guild_id: nil,
          channel_id: channel_id,
          user: %{id: user_id, username: "dm_user"},
          member: nil,
          token: "dm_token_mno345",
          version: 1,
          locale: "en-US"
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.guild_discord_id == nil
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles interaction with locale information" do
      guild_id = 333_444_555
      channel_id = 999_111_222
      user_id = 444_555_666

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "locale_user"})}
      end)

      interaction_struct =
        interaction(%{
          id: 888_999_111,
          application_id: 222_333_444,
          type: 2,
          data: %{
            id: 666_777_888,
            name: "locale_command",
            type: 1
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "locale_user"},
            nick: nil
          },
          token: "locale_token_stu901",
          version: 1,
          locale: "fr",
          guild_locale: "en-US"
        })

      created =
        TestApp.Discord.interaction_from_discord!(
          %{data: interaction_struct},
          load: [:guild, :channel, :user]
        )

      assert created.discord_id == interaction_struct.id
      assert created.locale == "fr"
      assert created.guild_locale == "en-US"
      assert created.guild.discord_id == guild_id
      assert created.channel.discord_id == channel_id
      assert created.user.discord_id == user_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing interaction instead of creating duplicate" do
      guild_id = 444_555_666
      channel_id = 777_888_999
      user_id = 987_654_321

      Mimic.stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      Mimic.stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, guild_id: guild_id, name: "test-channel"})}
      end)

      Mimic.stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      discord_id = 555_666_777

      initial_struct =
        interaction(%{
          id: discord_id,
          application_id: 123_456_789,
          type: 2,
          data: %{
            id: 111_222_333,
            name: "original_command",
            type: 1
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "original_user"},
            nick: "Original"
          },
          token: "original_token",
          version: 1,
          locale: "en-US"
        })

      {:ok, original} =
        TestApp.Discord.interaction_from_discord(%{data: initial_struct})

      updated_struct =
        interaction(%{
          id: discord_id,
          application_id: 123_456_789,
          type: 2,
          data: %{
            id: 111_222_333,
            name: "updated_command",
            type: 1
          },
          guild_id: guild_id,
          channel_id: channel_id,
          member: %{
            user: %{id: user_id, username: "updated_user"},
            nick: "Updated"
          },
          token: "updated_token",
          version: 1,
          locale: "fr"
        })

      {:ok, updated} =
        TestApp.Discord.interaction_from_discord(%{data: updated_struct})

      assert updated.id == original.id
      assert updated.token == "updated_token"
      assert updated.locale == "fr"
    end
  end
end
