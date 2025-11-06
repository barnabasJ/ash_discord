defmodule AshDiscord.Consumer.Handler.InteractionTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Interaction
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "routes application command to interaction router and persists to database" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      interaction_data =
        interaction(%{
          type: 2,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          user: user_data,
          data: %{name: "hello", options: []}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Interaction,
        guild: nil,
        user: nil
      }

      assert {:ok, response} =
               Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)

      assert is_map(response)

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_data.id
      assert created.guild.discord_id == guild_data.id
      assert created.channel.discord_id == channel_data.id
      assert created.user.discord_id == user_data.id
    end

    @tag :fixed
    test "persists non-application command interaction types" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      interaction_data =
        interaction(%{
          type: 3,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          user: user_data
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Interaction,
        guild: nil,
        user: nil
      }

      assert :ok = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_data.id
      assert created.type == 3
      assert created.guild.discord_id == guild_data.id
      assert created.channel.discord_id == channel_data.id
      assert created.user.discord_id == user_data.id
    end

    @tag :fixed
    test "sends error response for unknown command and persists interaction" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      interaction_data =
        interaction(%{
          type: 2,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          user: user_data,
          data: %{name: "unknown_command", options: []}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn interaction_id, token, response ->
        assert interaction_id == interaction_data.id
        assert token == interaction_data.token
        assert response.type == 4
        assert response.data.flags == 64
        {:ok}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Interaction,
        guild: nil,
        user: nil
      }

      assert :ok = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)

      [created] =
        TestApp.Discord.Interaction
        |> Ash.Query.load([:guild, :channel, :user])
        |> Ash.read!(authorize?: false)

      assert created.discord_id == interaction_data.id
      assert created.guild.discord_id == guild_data.id
      assert created.channel.discord_id == channel_data.id
      assert created.user.discord_id == user_data.id
    end
  end
end
