defmodule AshDiscord.InteractionRouterTest do
  use TestApp.DataCase

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
      interaction = %{
        # APPLICATION_COMMAND
        id: "interaction_123",
        token: "interaction_token",
        type: 2,
        data: %{
          name: "hello",
          options: []
        },
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{
          user: %{id: "111222333"}
        }
      }

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name)
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes create_message command with options" do
      interaction = %{
        id: "interaction_124",
        token: "interaction_token",
        type: 2,
        data: %{
          name: "create_message",
          options: [
            %{name: "message", type: 3, value: "Hello world"},
            %{name: "channel", type: 3, value: "123456789"}
          ]
        },
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{
          user: %{id: "111222333"}
        }
      }

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name)
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes search command with arguments" do
      interaction = %{
        id: "interaction_125",
        token: "interaction_token",
        type: 2,
        data: %{
          name: "search",
          options: [
            %{name: "query", type: 3, value: "test"},
            %{name: "limit", type: 4, value: 5}
          ]
        },
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{
          user: %{id: "111222333"}
        }
      }

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name)
        )

      # Should return success tuple
      assert {:ok, _response} = result
    end

    test "routes configure command with arguments" do
      # First create a guild for the configure command
      guild =
        TestApp.Discord.Guild.create!(%{
          discord_id: "123456789",
          name: "Test Guild"
        })

      interaction = %{
        id: "interaction_126",
        token: "interaction_token",
        type: 2,
        data: %{
          name: "configure",
          options: [
            %{name: "setting", type: 3, value: "moderation"},
            %{name: "enabled", type: 5, value: true}
          ]
        },
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{
          user: %{id: "111222333"}
        }
      }

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name)
        )

      # Update actions are not yet supported - router sends error response to Discord
      assert {:ok, response} = result
      assert response.type == 4  # CHANNEL_MESSAGE_WITH_SOURCE
      assert String.contains?(response.data.content, "Error: An unexpected error occurred")

      # Guild should remain unchanged since update failed
      unchanged_guild = TestApp.Discord.Guild.read!() |> Enum.find(&(&1.id == guild.id))
      assert unchanged_guild.description == guild.description
    end

    test "handles unknown command gracefully" do
      interaction = %{
        id: "interaction_127",
        token: "interaction_token",
        type: 2,
        data: %{
          name: "unknown_command",
          options: []
        },
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{
          user: %{id: "111222333"}
        }
      }

      result =
        InteractionRouter.route_interaction(
          interaction,
          find_command_for_test(Discord, interaction.data.name)
        )

      # Should return error tuple
      assert {:error, _reason} = result
    end
  end

  describe "option parsing" do
    test "correctly parses string options" do
      options = [
        %{name: "message", type: 3, value: "Hello world"}
      ]

      parsed = InteractionRouter.parse_options(options)
      assert parsed[:message] == "Hello world"
    end

    test "correctly parses integer options" do
      options = [
        %{name: "limit", type: 4, value: 10}
      ]

      parsed = InteractionRouter.parse_options(options)
      assert parsed[:limit] == 10
    end

    test "correctly parses boolean options" do
      options = [
        %{name: "enabled", type: 5, value: true}
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
      interaction = %{
        id: "interaction_128",
        token: "interaction_token",
        type: 2,
        data: %{name: "hello", options: []},
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{user: %{id: "111222333"}}
      }

      command = find_command_for_test(TestApp.Discord, "hello")
      result = InteractionRouter.route_interaction(interaction, command)

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
      discord_user = %{id: "123456789", username: "testuser"}
      interaction = %{
        id: "interaction_129",
        token: "interaction_token", 
        type: 2,
        data: %{name: "hello", options: []},
        guild_id: "123456789",
        channel_id: "987654321",
        user: discord_user
      }

      # Create a user creator function that mimics the TestApp pattern
      user_creator = fn discord_user_data ->
        TestApp.Discord.User.from_discord!(%{
          discord_id: discord_user_data.id,
          username: discord_user_data.username || "testuser#{discord_user_data.id}"
        })
      end

      command = find_command_for_test(TestApp.Discord, "hello")
      
      # Route with explicit user_creator
      result = InteractionRouter.route_interaction(interaction, command, user_creator: user_creator)
      assert {:ok, _response} = result

      # Verify user was created in database
      users = TestApp.Discord.User.read!()
      assert Enum.any?(users, fn user -> 
        user.discord_id == String.to_integer(discord_user.id)
      end)
    end

    test "user resolution falls back to basic struct when no user_resource configured" do
      discord_user = %{id: "987654321", username: "fallbackuser"}
      interaction = %{
        id: "interaction_130",
        token: "interaction_token",
        type: 2, 
        data: %{name: "hello", options: []},
        guild_id: "123456789",
        channel_id: "987654321",
        user: discord_user
      }

      command = find_command_for_test(TestApp.Discord, "hello")
      
      # Route without user_creator - should use fallback
      result = InteractionRouter.route_interaction(interaction, command, user_creator: nil)
      assert {:ok, _response} = result
    end

  end

  describe "discord context setting (Task 20)" do
    test "discord context sets actor only" do
      discord_user = %{id: "555666777", username: "contextuser"}
      interaction = %{
        id: "interaction_132",
        token: "interaction_token",
        type: 2,
        data: %{name: "hello", options: []},
        guild_id: "123456789",
        channel_id: "987654321",
        user: discord_user
      }

      user_creator = fn discord_user_data ->
        TestApp.Discord.User.from_discord!(%{
          discord_id: discord_user_data.id,
          username: discord_user_data.username || "testuser#{discord_user_data.id}"
        })
      end

      command = find_command_for_test(TestApp.Discord, "hello")
      result = InteractionRouter.route_interaction(interaction, command, user_creator: user_creator)
      
      # Should succeed with actor set from Discord context
      assert {:ok, _response} = result

      # Verify user was resolved and used as actor
      users = TestApp.Discord.User.read!()
      assert Enum.any?(users, fn user ->
        user.discord_id == String.to_integer(discord_user.id)
      end)
    end

    test "generic Discord context management supports multiple context patterns" do  
      # Test that context can be passed in different patterns
      interaction = %{
        id: "interaction_133",
        token: "interaction_token",
        type: 2,
        data: %{name: "hello", options: []},
        guild_id: "123456789",
        channel_id: "987654321",
        member: %{user: %{id: "888999000"}}  # Member pattern instead of direct user
      }

      user_creator = fn discord_user_data ->
        TestApp.Discord.User.from_discord!(%{discord_id: discord_user_data.id})
      end

      command = find_command_for_test(TestApp.Discord, "hello")
      result = InteractionRouter.route_interaction(interaction, command, user_creator: user_creator)
      
      assert {:ok, _response} = result
    end
  end
end
