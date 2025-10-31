defmodule AshDiscord.Changes.FromDiscord.InteractionTest do
  @moduledoc """
  Comprehensive tests for Interaction entity from_discord transformation.

  Tests struct-first pattern and upsert behavior.

  Note: Interactions are ephemeral and cannot be fetched from Discord API,
  so API fallback pattern is not applicable.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    @tag :fixed
    test "creates interaction from discord struct with all attributes" do
      guild_data = guild(%{id: 111_222_333})
      channel_data = channel(%{id: 444_555_666, guild_id: 111_222_333})
      user_data = user(%{id: 777_888_999, username: "test_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: 111_222_333,
          channel_id: 444_555_666,
          member: %{
            user: %{id: 777_888_999, username: "test_user"},
            nick: "TestNick"
          },
          user: nil,
          token: "interaction_token_abc123",
          version: 1,
          locale: "en-US",
          guild_locale: "en-US"
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.application_id == interaction_struct.application_id
      assert created.type == interaction_struct.type
      assert created.token == interaction_struct.token
      assert created.version == interaction_struct.version
      assert created.locale == interaction_struct.locale
      assert created.guild_locale == interaction_struct.guild_locale

      assert created.guild.discord_id == 111_222_333
      assert created.channel.discord_id == 444_555_666
      assert created.user.discord_id == 777_888_999
    end

    test "handles slash command interaction" do
      guild_data = guild(%{id: 444_555_666})
      channel_data = channel(%{id: 777_888_999, guild_id: 444_555_666})
      user_data = user(%{id: 333_444_555, username: "slash_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 333_444_555, username: "slash_user"},
            nick: nil
          },
          token: "slash_token_def456",
          version: 1
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.type == 2
      assert created.guild.discord_id == 444_555_666
      assert created.channel.discord_id == 777_888_999
      assert created.user.discord_id == 333_444_555
    end

    test "handles message component interaction" do
      guild_data = guild(%{id: 333_444_555})
      channel_data = channel(%{id: 666_777_888, guild_id: 333_444_555})
      user_data = user(%{id: 999_111_222, username: "button_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      interaction_struct =
        interaction(%{
          id: 111_222_333,
          application_id: 777_888_999,
          type: 3,
          data: %{
            custom_id: "button_click",
            component_type: 2
          },
          guild_id: 333_444_555,
          channel_id: 666_777_888,
          member: %{
            user: %{id: 999_111_222, username: "button_user"},
            nick: "ButtonClicker"
          },
          token: "component_token_ghi789",
          version: 1,
          message: %{
            id: 222_333_444,
            content: "Click the button!"
          }
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.type == 3
      assert created.guild.discord_id == 333_444_555
      assert created.channel.discord_id == 666_777_888
      assert created.user.discord_id == 999_111_222
    end

    test "handles modal submit interaction" do
      guild_data = guild(%{id: 555_666_777})
      channel_data = channel(%{id: 111_222_333, guild_id: 555_666_777})
      user_data = user(%{id: 222_333_444, username: "modal_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          member: %{
            user: %{id: 222_333_444, username: "modal_user"},
            nick: nil
          },
          token: "modal_token_jkl012",
          version: 1
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.type == 5
      assert created.guild.discord_id == 555_666_777
      assert created.channel.discord_id == 111_222_333
      assert created.user.discord_id == 222_333_444
    end

    @tag :fixed
    test "handles DM interaction without guild" do
      channel_data = channel(%{id: 777_888_999, guild_id: nil})
      user_data = user(%{id: 111_222_333, username: "dm_user"})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          channel_id: 777_888_999,
          user: %{id: 111_222_333, username: "dm_user"},
          member: nil,
          token: "dm_token_mno345",
          version: 1,
          locale: "en-US"
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.guild_discord_id == nil
      assert created.channel.discord_id == 777_888_999
      assert created.user.discord_id == 111_222_333
    end

    test "handles interaction with locale information" do
      guild_data = guild(%{id: 333_444_555})
      channel_data = channel(%{id: 999_111_222, guild_id: 333_444_555})
      user_data = user(%{id: 444_555_666, username: "locale_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: 333_444_555,
          channel_id: 999_111_222,
          member: %{
            user: %{id: 444_555_666, username: "locale_user"},
            nick: nil
          },
          token: "locale_token_stu901",
          version: 1,
          locale: "fr",
          guild_locale: "en-US"
        })

      TestApp.Discord.interaction_from_discord!(
        %{data: interaction_struct},
        authorize?: false
      )

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_struct.id
      assert created.locale == "fr"
      assert created.guild_locale == "en-US"
      assert created.guild.discord_id == 333_444_555
      assert created.channel.discord_id == 999_111_222
      assert created.user.discord_id == 444_555_666
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing interaction instead of creating duplicate" do
      guild_data = guild(%{id: 444_555_666})
      channel_data = channel(%{id: 777_888_999, guild_id: 444_555_666})
      user_data = user(%{id: 987_654_321, username: "original_user"})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 987_654_321, username: "original_user"},
            nick: "Original"
          },
          token: "original_token",
          version: 1,
          locale: "en-US"
        })

      {:ok, original} =
        TestApp.Discord.interaction_from_discord(%{data: initial_struct}, authorize?: false)

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
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 987_654_321, username: "updated_user"},
            nick: "Updated"
          },
          token: "updated_token",
          version: 1,
          locale: "fr"
        })

      {:ok, updated} =
        TestApp.Discord.interaction_from_discord(%{data: updated_struct}, authorize?: false)

      assert updated.id == original.id
      assert updated.discord_id == original.discord_id

      assert updated.token == "updated_token"
      assert updated.locale == "fr"
    end
  end
end
