defmodule AshDiscord.Consumer.Handler.Guild.ScheduledEventTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators.Discord
  import Mimic

  require Ash.Query

  alias AshDiscord.Consumer.Handler.Guild.ScheduledEvent
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  setup :verify_on_exit!

  describe "create/4" do
    test "creates guild scheduled event in database" do
      event_id = generate_snowflake()
      guild_id = generate_snowflake()

      event_data = %Nostrum.Struct.Guild.ScheduledEvent{
        id: event_id,
        guild_id: guild_id,
        channel_id: nil,
        creator_id: generate_snowflake(),
        name: "Test Event",
        description: "A test scheduled event",
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: ~U[2025-12-01 12:00:00Z],
        privacy_level: 2,
        status: 1,
        entity_type: 3,
        entity_id: nil,
        entity_metadata: %Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata{
          location: "Discord HQ"
        },
        creator: nil,
        user_count: 0
      }

      {:ok, event_payload} = Payloads.GuildScheduledEvent.new(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      assert :ok =
               ScheduledEvent.create(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify scheduled event was created in database
      events =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.filter(discord_id: event_id)
        |> Ash.read!()

      assert length(events) == 1

      created_event = hd(events)
      assert created_event.discord_id == event_id
      assert created_event.guild_id == guild_id
      assert created_event.name == "Test Event"
      assert created_event.description == "A test scheduled event"
      assert created_event.status == 1
      assert created_event.entity_type == 3
      assert created_event.entity_metadata_location == "Discord HQ"
    end

    test "returns :ok when no scheduled event resource configured" do
      # Use a test consumer without scheduled event resource configured
      defmodule NoScheduledEventConsumer do
        use AshDiscord.Consumer.Dsl

        ash_discord_consumer do
          domains([TestApp.Discord])
        end
      end

      event_payload = %Payloads.GuildScheduledEvent{
        id: generate_snowflake(),
        guild_id: generate_snowflake(),
        channel_id: nil,
        creator_id: nil,
        name: "Test",
        description: nil,
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: nil,
        privacy_level: 2,
        status: 1,
        entity_type: 1,
        entity_id: nil,
        entity_metadata: nil,
        creator: nil,
        user_count: nil
      }

      context = %AshDiscord.Context{
        consumer: NoScheduledEventConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               ScheduledEvent.create(
                 NoScheduledEventConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "update/4" do
    test "updates existing guild scheduled event in database" do
      event_id = generate_snowflake()
      guild_id = generate_snowflake()

      # Create initial event
      initial_event = %Nostrum.Struct.Guild.ScheduledEvent{
        id: event_id,
        guild_id: guild_id,
        channel_id: nil,
        creator_id: nil,
        name: "Original Event",
        description: "Original description",
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: nil,
        privacy_level: 2,
        status: 1,
        entity_type: 3,
        entity_id: nil,
        entity_metadata: %Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata{
          location: "Old Location"
        },
        creator: nil,
        user_count: 5
      }

      {:ok, initial_payload} = Payloads.GuildScheduledEvent.new(initial_event)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      # Create the event
      :ok =
        ScheduledEvent.create(
          TestConsumer,
          initial_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      # Update the event
      updated_event = %Nostrum.Struct.Guild.ScheduledEvent{
        id: event_id,
        guild_id: guild_id,
        channel_id: nil,
        creator_id: nil,
        name: "Updated Event",
        description: "Updated description",
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: ~U[2025-12-01 14:00:00Z],
        privacy_level: 2,
        status: 2,
        entity_type: 3,
        entity_id: nil,
        entity_metadata: %Nostrum.Struct.Guild.ScheduledEvent.EntityMetadata{
          location: "New Location"
        },
        creator: nil,
        user_count: 10
      }

      {:ok, updated_payload} = Payloads.GuildScheduledEvent.new(updated_event)

      assert :ok =
               ScheduledEvent.update(
                 TestConsumer,
                 updated_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify event was updated in database
      events =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.filter(discord_id: event_id)
        |> Ash.read!()

      assert length(events) == 1

      updated = hd(events)
      assert updated.discord_id == event_id
      assert updated.name == "Updated Event"
      assert updated.description == "Updated description"
      assert updated.status == 2
      assert updated.entity_metadata_location == "New Location"
      assert updated.user_count == 10
    end
  end

  describe "delete/4" do
    test "deletes guild scheduled event from database" do
      event_id = generate_snowflake()
      guild_id = generate_snowflake()

      # Create the event first
      event_data = %Nostrum.Struct.Guild.ScheduledEvent{
        id: event_id,
        guild_id: guild_id,
        channel_id: nil,
        creator_id: nil,
        name: "Event to Delete",
        description: nil,
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: nil,
        privacy_level: 2,
        status: 1,
        entity_type: 1,
        entity_id: nil,
        entity_metadata: nil,
        creator: nil,
        user_count: nil
      }

      {:ok, event_payload} = Payloads.GuildScheduledEvent.new(event_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      :ok =
        ScheduledEvent.create(
          TestConsumer,
          event_payload,
          %Nostrum.Struct.WSState{},
          context
        )

      # Verify event exists
      events_before =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.filter(discord_id: event_id)
        |> Ash.read!()

      assert length(events_before) == 1

      # Delete the event
      assert :ok =
               ScheduledEvent.delete(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify event was deleted
      events_after =
        TestApp.Discord.GuildScheduledEvent
        |> Ash.Query.filter(discord_id: event_id)
        |> Ash.read!()

      assert length(events_after) == 0
    end

    test "returns :ok when event does not exist" do
      event_id = generate_snowflake()
      guild_id = generate_snowflake()

      event_payload = %Payloads.GuildScheduledEvent{
        id: event_id,
        guild_id: guild_id,
        channel_id: nil,
        creator_id: nil,
        name: "Non-existent Event",
        description: nil,
        scheduled_start_time: ~U[2025-12-01 10:00:00Z],
        scheduled_end_time: nil,
        privacy_level: 2,
        status: 1,
        entity_type: 1,
        entity_id: nil,
        entity_metadata: nil,
        creator: nil,
        user_count: nil
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      # Deleting non-existent event should succeed (idempotent)
      assert :ok =
               ScheduledEvent.delete(
                 TestConsumer,
                 event_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "user_add/4" do
    test "returns :ok for informational event" do
      event_add = %Payloads.GuildScheduledEventUserAdd{
        guild_scheduled_event_id: generate_snowflake(),
        user_id: generate_snowflake(),
        guild_id: generate_snowflake()
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      assert :ok =
               ScheduledEvent.user_add(
                 TestConsumer,
                 event_add,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "user_remove/4" do
    test "returns :ok for informational event" do
      event_remove = %Payloads.GuildScheduledEventUserRemove{
        guild_scheduled_event_id: generate_snowflake(),
        user_id: generate_snowflake(),
        guild_id: generate_snowflake()
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildScheduledEvent,
        guild: nil,
        user: nil
      }

      assert :ok =
               ScheduledEvent.user_remove(
                 TestConsumer,
                 event_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
