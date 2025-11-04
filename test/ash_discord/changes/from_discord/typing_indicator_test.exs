defmodule AshDiscord.Changes.FromDiscord.TypingIndicatorTest do
  @moduledoc """
  Comprehensive tests for TypingIndicator entity from_discord transformation.

  Tests struct-first pattern and upsert behavior. No API fallback as typing events
  are not fetchable from the Discord API.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates typing indicator from discord struct with all attributes" do
      user_id = 123_456_789
      channel_id = 555_666_777
      guild_id = 111_222_333

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: 1_673_784_600
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel, :guild]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.channel.discord_id == channel_id
      assert created_typing.guild.discord_id == guild_id
      assert created_typing.timestamp == DateTime.from_unix!(typing_struct.timestamp, :second)
    end

    @tag :fixed
    test "handles DM typing indicator without guild_id" do
      user_id = 987_654_321
      channel_id = 777_888_999

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: nil,
          timestamp: 1_673_788_200
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.channel.discord_id == channel_id
      assert created_typing.guild_discord_id == nil
      assert created_typing.timestamp == DateTime.from_unix!(typing_struct.timestamp, :second)
    end

    @tag :fixed
    test "handles recent typing indicator" do
      user_id = 111_222_333
      channel_id = 444_555_666
      guild_id = 777_888_999
      current_timestamp = System.system_time(:second)

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: current_timestamp
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel, :guild]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.timestamp == DateTime.from_unix!(current_timestamp, :second)
    end

    @tag :fixed
    test "handles old typing indicator" do
      user_id = 333_444_555
      channel_id = 666_777_888
      guild_id = 999_111_222
      old_timestamp = System.system_time(:second) - 3600

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: old_timestamp
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel, :guild]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.timestamp == DateTime.from_unix!(old_timestamp, :second)
    end

    @tag :fixed
    test "handles typing indicator in voice channel" do
      user_id = 555_666_777
      channel_id = 888_999_111
      guild_id = 222_333_444

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: 1_673_792_200
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel, :guild]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.channel.discord_id == channel_id
    end

    @tag :fixed
    test "handles typing indicator in thread" do
      user_id = 777_888_999
      channel_id = 111_333_555
      guild_id = 444_666_888

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      typing_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: 1_673_795_800
        })

      created_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: typing_struct},
          load: [:user, :channel, :guild]
        )

      assert created_typing.user.discord_id == user_id
      assert created_typing.channel.discord_id == channel_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing typing indicator instead of creating duplicate" do
      user_id = 555_666_777
      channel_id = 111_222_333
      guild_id = 444_555_666

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: 1_673_784_600
        })

      original_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: initial_struct},
          load: [:user, :channel, :guild]
        )

      updated_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: 1_673_788_200
        })

      updated_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: updated_struct},
          load: [:user, :channel, :guild]
        )

      assert updated_typing.id == original_typing.id
      assert updated_typing.user.discord_id == user_id
      assert updated_typing.channel.discord_id == channel_id
      assert updated_typing.timestamp == DateTime.from_unix!(1_673_788_200, :second)
    end

    @tag :fixed
    test "upsert works with guild context changes" do
      user_id = 333_444_555
      channel_id = 777_888_999
      initial_guild_id = 111_222_333
      updated_guild_id = 666_777_888

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn guild_id when guild_id in [initial_guild_id, updated_guild_id] ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: initial_guild_id,
          timestamp: 1_673_784_600
        })

      original_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: initial_struct},
          load: [:user, :channel, :guild]
        )

      updated_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: updated_guild_id,
          timestamp: 1_673_788_200
        })

      updated_typing =
        TestApp.Discord.typing_indicator_from_discord!(%{data: updated_struct},
          load: [:user, :channel, :guild]
        )

      assert updated_typing.id == original_typing.id
      assert updated_typing.user.discord_id == user_id
      assert updated_typing.channel.discord_id == channel_id
      assert updated_typing.guild.discord_id == updated_guild_id
      assert updated_typing.timestamp == DateTime.from_unix!(1_673_788_200, :second)
    end
  end
end
