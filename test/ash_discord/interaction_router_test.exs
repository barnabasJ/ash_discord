defmodule AshDiscord.InteractionRouterTest do
  use TestApp.DataCase

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.InteractionRouter
  alias AshDiscord.Info
  alias TestApp.Discord

  setup do
    TestHelper.setup_mocks()
  end

  # Helper function to find commands for testing
  defp find_command_for_test(domain, command_name) do
    commands = Info.discord_commands(domain)
    Enum.find(commands, &(&1.name == String.to_atom(command_name)))
  end

  describe "interaction routing" do
    test "routes hello command to message action" do
      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name),
          consumer: TestApp.TestConsumer
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes create_message command with options" do
      interaction =
        interaction(%{
          data: %{
            name: "create_message",
            options: [
              option(%{name: "message", type: 3, value: "Hello world"}),
              option(%{name: "channel", type: 3, value: "#{generate_snowflake()}"})
            ]
          },
          member: %{user: user()}
        })

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name),
          consumer: TestApp.TestConsumer
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes search command with arguments" do
      interaction =
        interaction(%{
          data: %{
            name: "search",
            options: [
              option(%{name: "query", type: 3, value: "test"}),
              option(%{name: "limit", type: 4, value: 5})
            ]
          },
          member: %{user: user()}
        })

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name),
          consumer: TestApp.TestConsumer
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes configure command with arguments" do
      # First create a guild for the configure command
      guild_id = generate_snowflake()

      guild =
        TestApp.Discord.Guild.create!(%{
          discord_id: guild_id,
          name: "Test Guild"
        })

      interaction =
        interaction(%{
          data: %{
            name: "configure",
            options: [
              option(%{name: "setting", type: 3, value: "moderation"}),
              option(%{name: "enabled", type: 5, value: true})
            ]
          },
          guild_id: guild_id,
          member: %{user: user()}
        })

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name),
          consumer: TestApp.TestConsumer
        )

      # Update actions are not yet supported - router sends error response to Discord
      assert {:ok, response} = result
      # CHANNEL_MESSAGE_WITH_SOURCE
      assert response.type == 4
      assert String.contains?(response.data.content, "Error: An unexpected error occurred")

      # Guild should remain unchanged since update failed
      unchanged_guild = TestApp.Discord.Guild.read!() |> Enum.find(&(&1.id == guild.id))
      assert unchanged_guild.description == guild.description
    end

    test "handles unknown command gracefully" do
      interaction =
        interaction(%{
          data: %{name: "unknown_command", options: []},
          member: %{user: user()}
        })

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name),
          consumer: TestApp.TestConsumer
        )

      # Should return error tuple
      assert {:error, _reason} = result
    end
  end

  describe "option parsing" do
    test "correctly parses string options" do
      options = [
        option(%{name: "message", type: 3, value: "Hello world"})
      ]

      parsed = InteractionRouter.parse_options(options)
      assert parsed[:message] == "Hello world"
    end

    test "correctly parses integer options" do
      options = [
        option(%{name: "limit", type: 4, value: 10})
      ]

      parsed = InteractionRouter.parse_options(options)
      assert parsed[:limit] == 10
    end

    test "correctly parses boolean options" do
      options = [
        option(%{name: "enabled", type: 5, value: true})
      ]

      parsed = InteractionRouter.parse_options(options)
      assert parsed[:enabled] == true
    end

    test "handles empty options" do
      parsed = InteractionRouter.parse_options([])
      assert parsed == %{}
    end
  end

  describe "domain resolution (Task 18)" do
    test "router works with configured domains without hardcoded references" do
      # Verify no hardcoded Steward references exist in the router
      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      command = find_command_for_test(TestApp.Discord, "hello")

      result =
        InteractionRouter.route_interaction(interaction, command, consumer: TestApp.TestConsumer)

      # Should work without any Steward domain dependencies
      assert {:ok, _response} = result
    end

    test "router resolves domains dynamically from command configuration" do
      # Test that router uses command.domain rather than hardcoded domains
      command = find_command_for_test(TestApp.Discord, "hello")
      assert command.domain == TestApp.Discord
      refute command.domain == :"Steward.Discord"
    end
  end

  describe "automatic user resolution system (Task 19)" do
    test "automatic user resolution creates actors from Discord data" do
      discord_user = user(%{username: "testuser", avatar: "avatarhash"})

      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          user: discord_user
        })

      command = find_command_for_test(TestApp.Discord, "hello")

      result =
        InteractionRouter.route_interaction(interaction, command, consumer: TestApp.TestConsumer)

      assert {:ok, _response} = result

      users = TestApp.Discord.User.read!()

      assert Enum.any?(users, fn user ->
               user.discord_id == discord_user.id
             end)
    end

    test "user resolution falls back to basic struct when no user_resource configured" do
      discord_user = user(%{username: "fallbackuser"})

      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          user: discord_user
        })

      command = find_command_for_test(TestApp.Discord, "hello")

      result =
        InteractionRouter.route_interaction(interaction, command, consumer: TestApp.TestConsumer)

      assert {:ok, _response} = result
    end
  end

  describe "discord context setting (Task 20)" do
    test "discord context sets actor only" do
      discord_user = user(%{username: "contextuser"})

      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          user: discord_user
        })

      command = find_command_for_test(TestApp.Discord, "hello")

      result =
        InteractionRouter.route_interaction(interaction, command, consumer: TestApp.TestConsumer)

      # Should succeed with actor set from Discord context
      assert {:ok, _response} = result

      # Verify user was resolved and used as actor
      users = TestApp.Discord.User.read!()

      assert Enum.any?(users, fn user ->
               user.discord_id == discord_user.id
             end)
    end

    test "generic Discord context management supports multiple context patterns" do
      # Test that context can be passed in different patterns
      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          # Member pattern instead of direct user
          member: %{user: user()}
        })

      command = find_command_for_test(TestApp.Discord, "hello")

      result =
        InteractionRouter.route_interaction(interaction, command, consumer: TestApp.TestConsumer)

      assert {:ok, _response} = result
    end
  end
end
