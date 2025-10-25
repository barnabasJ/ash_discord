defmodule AshDiscord.Consumer.Handler.GuildScheduledEventTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildScheduledEvent
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/4" do
    @tag :fixed
    test "creates guild scheduled event in database with all relationships" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      creator_data = user()

      event_data =
        guild_scheduled_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          creator_id: creator_data.id,
          entity_type: 2
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: creator_data}, authorize?: false)

      event_payload = Payloads.GuildScheduledEvent.new!(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               GuildScheduledEvent.create(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_event] =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.load([:guild, :channel, :creator])
        |> Ash.read!(authorize?: false)

      assert created_event.discord_id == event_data.id
      assert created_event.guild.discord_id == event_data.guild_id
      assert created_event.channel.discord_id == event_data.channel_id
      assert created_event.creator.discord_id == event_data.creator_id
      assert created_event.name == event_data.name
      assert created_event.description == event_data.description
      assert created_event.status == event_data.status
      assert created_event.entity_type == event_data.entity_type
    end
  end

  describe "update/4" do
    @tag :fixed
    test "updates existing guild scheduled event in database with all relationships" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      creator_data = user()

      initial_event =
        guild_scheduled_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          creator_id: creator_data.id,
          entity_type: 2,
          name: "Original Event",
          description: "Original description",
          status: 1,
          user_count: 5
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: creator_data}, authorize?: false)

      initial_payload = Payloads.GuildScheduledEvent.new!(initial_event)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      :ok =
        GuildScheduledEvent.create(
          TestConsumer,
          initial_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      updated_event =
        guild_scheduled_event(%{
          id: initial_event.id,
          guild_id: initial_event.guild_id,
          channel_id: initial_event.channel_id,
          creator_id: initial_event.creator_id,
          entity_type: 2,
          name: "Updated Event",
          description: "Updated description",
          scheduled_end_time: ~U[2025-12-01 14:00:00Z],
          status: 2,
          user_count: 10
        })

      updated_payload = Payloads.GuildScheduledEvent.new!(updated_event)

      assert :ok =
               GuildScheduledEvent.update(
                 TestConsumer,
                 updated_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated] =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.load([:guild, :channel, :creator])
        |> Ash.read!(authorize?: false)

      assert updated.discord_id == updated_event.id
      assert updated.guild.discord_id == updated_event.guild_id
      assert updated.channel.discord_id == updated_event.channel_id
      assert updated.creator.discord_id == updated_event.creator_id
      assert updated.name == "Updated Event"
      assert updated.description == "Updated description"
      assert updated.status == 2
      assert updated.user_count == 10
    end
  end

  describe "delete/4" do
    @tag :fixed
    test "deletes guild scheduled event from database" do
      event_data = guild_scheduled_event(%{entity_type: 1, entity_metadata: nil})

      event_payload = Payloads.GuildScheduledEvent.new!(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      :ok =
        GuildScheduledEvent.create(
          TestConsumer,
          event_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      [_created] = TestApp.Discord.GuildScheduledEvent.read!(authorize?: false)

      assert :ok =
               GuildScheduledEvent.delete(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [] = TestApp.Discord.GuildScheduledEvent.read!(authorize?: false)
    end

    @tag :fixed
    test "returns :ok when event does not exist" do
      event_data = guild_scheduled_event(%{entity_type: 1, entity_metadata: nil})

      event_payload = Payloads.GuildScheduledEvent.new!(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               GuildScheduledEvent.delete(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "user_add/4" do
    @tag :fixed
    test "creates guild scheduled event user subscription in database" do
      event_data = guild_scheduled_event()
      guild_data = guild(%{id: event_data.guild_id})
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      event_payload = Payloads.GuildScheduledEvent.new!(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      :ok =
        GuildScheduledEvent.create(
          TestConsumer,
          event_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      event_add = %Payloads.GuildScheduledEventUserAdd{
        guild_scheduled_event_id: event_data.id,
        user_id: user_data.id,
        guild_id: event_data.guild_id
      }

      user_context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEventUser,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               GuildScheduledEvent.user_add(
                 TestConsumer,
                 event_add,
                 %Nostrum.Struct.WSState{},
                 user_context
               )

      [subscription] =
        TestApp.Discord.GuildScheduledEventUser
        |> Ash.Query.load([:guild_scheduled_event, :user, :guild])
        |> Ash.read!(authorize?: false)

      assert subscription.guild_scheduled_event.discord_id == event_data.id
      assert subscription.user.discord_id == user_data.id
      assert subscription.guild.discord_id == event_data.guild_id
    end
  end

  describe "user_remove/4" do
    @tag :fixed
    test "removes guild scheduled event user subscription from database" do
      event_data = guild_scheduled_event()
      guild_data = guild(%{id: event_data.guild_id})
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      event_payload = Payloads.GuildScheduledEvent.new!(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      :ok =
        GuildScheduledEvent.create(
          TestConsumer,
          event_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      event_add = %Payloads.GuildScheduledEventUserAdd{
        guild_scheduled_event_id: event_data.id,
        user_id: user_data.id,
        guild_id: event_data.guild_id
      }

      user_context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEventUser,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      :ok =
        GuildScheduledEvent.user_add(
          TestConsumer,
          event_add,
          %Nostrum.Struct.WSState{},
          user_context
        )

      [subscription] =
        TestApp.Discord.GuildScheduledEventUser
        |> Ash.Query.load([:guild_scheduled_event, :user, :guild])
        |> Ash.read!(authorize?: false)

      assert subscription.guild_scheduled_event.discord_id == event_data.id
      assert subscription.user.discord_id == user_data.id
      assert subscription.guild.discord_id == event_data.guild_id

      event_remove = %Payloads.GuildScheduledEventUserRemove{
        guild_scheduled_event_id: event_data.id,
        user_id: user_data.id,
        guild_id: event_data.guild_id
      }

      assert :ok =
               GuildScheduledEvent.user_remove(
                 TestConsumer,
                 event_remove,
                 %Nostrum.Struct.WSState{},
                 user_context
               )

      [] = TestApp.Discord.GuildScheduledEventUser.read!(authorize?: false)
    end
  end
end
