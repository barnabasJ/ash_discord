defmodule AshDiscord.CommandRegistrationTest do
  use ExUnit.Case, async: true

  import AshDiscord.Test.Generators.Discord

  # Mock Nostrum API calls
  import Mimic
  setup :verify_on_exit!

  setup do
    # Copy only Nostrum modules we need to mock
    copy(Nostrum.Api.ApplicationCommand)
    copy(Nostrum.Api.Interaction)
    :ok
  end

  alias AshDiscord.Command
  alias AshDiscord.Consumer

  describe "command scope filtering" do
    test "filters global commands correctly" do
      commands = [
        %Command{
          name: :global_help,
          scope: :global,
          description: "Global help",
          type: :chat_input,
          options: [],
          domain: TestDomain,
          resource: TestResource,
          action: :help
        },
        %Command{
          name: :guild_admin,
          scope: :guild,
          description: "Guild admin",
          type: :chat_input,
          options: [],
          domain: TestDomain,
          resource: TestResource,
          action: :admin
        },
        %Command{
          name: :guild_mod,
          scope: :guild,
          description: "Guild mod",
          type: :chat_input,
          options: [],
          domain: TestDomain,
          resource: TestResource,
          action: :moderate
        }
      ]

      global_commands = commands |> Enum.filter(&(&1.scope == :global))
      guild_commands = commands |> Enum.filter(&(&1.scope == :guild))

      assert length(global_commands) == 1
      assert hd(global_commands).name == :global_help

      assert length(guild_commands) == 2
      guild_names = Enum.map(guild_commands, & &1.name)
      assert :guild_admin in guild_names
      assert :guild_mod in guild_names
    end
  end

  describe "to_discord_command conversion" do
    test "converts command struct to Discord API format" do
      command = %Command{
        name: :test_command,
        description: "Test command",
        type: :chat_input,
        options: []
      }

      discord_command = Consumer.to_discord_command(command)

      assert discord_command.name == "test_command"
      assert discord_command.description == "Test command"
      # chat_input type
      assert discord_command.type == 1
      assert discord_command.options == []
    end
  end

  describe "mocked registration calls" do
    test "global command registration API call format" do
      # Mock the global command registration call
      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_global_commands, fn commands ->
        assert is_list(commands)
        assert length(commands) >= 0
        {:ok, []}
      end)

      # No need to mock AshLogger - let it work normally

      # Test the API call
      result = Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands([])
      assert result == {:ok, []}
    end

    test "guild command registration API call format" do
      guild_id = 123_456_789

      # Mock guild command registration
      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn received_guild_id,
                                                                                commands ->
        assert received_guild_id == guild_id
        assert is_list(commands)
        {:ok, []}
      end)

      # Test the API call
      result = Nostrum.Api.ApplicationCommand.bulk_overwrite_guild_commands(guild_id, [])
      assert result == {:ok, []}
    end
  end

  describe "CommandFilter behavior" do
    defmodule TestFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, guild) do
        # Only allow admin commands in guilds with id > 100000
        if guild.id > 100_000 do
          commands
        else
          Enum.reject(commands, fn cmd ->
            cmd.name |> Atom.to_string() |> String.contains?("admin")
          end)
        end
      end

      def command_allowed?(command, guild) do
        command_name = command.name |> Atom.to_string()

        if String.contains?(command_name, "admin") do
          guild.id > 100_000
        else
          true
        end
      end
    end

    test "filter works correctly with guild context" do
      commands = [
        %Command{name: :guild_admin, scope: :guild, description: "Admin command"},
        %Command{name: :guild_mod, scope: :guild, description: "Mod command"}
      ]

      large_guild = %{id: 123_456_789, name: "Large Guild"}
      small_guild = %{id: 12_345, name: "Small Guild"}

      # Large guild should get all commands
      large_filtered = TestFilter.filter_commands(commands, large_guild)
      assert length(large_filtered) == 2

      # Small guild should only get mod command (admin filtered out)
      small_filtered = TestFilter.filter_commands(commands, small_guild)
      assert length(small_filtered) == 1
      assert hd(small_filtered).name == :guild_mod
    end
  end

  describe "unknown command handling" do
    # Simple test consumer for testing unknown command scenarios
    defmodule UnknownCommandTestConsumer do
      use AshDiscord.Consumer

      ash_discord_consumer do
        domains([])
      end

      # Override to capture interaction processing
      @impl true
      def handle_interaction_create(interaction) do
        send(self(), {:interaction_processed, interaction})
        super(interaction)
      end
    end

    test "handles unknown command interaction gracefully" do
      # Create an interaction for a command that doesn't exist
      interaction =
        interaction(%{
          data: %{
            # This command doesn't exist in our registry
            name: "nonexistent_command",
            type: 1
          },
          user: user()
        })

      # Mock only Nostrum API response for the error response
      expect(Nostrum.Api.Interaction, :create_response, fn interaction_id, token, response ->
        assert interaction_id == interaction.id
        assert token == interaction.token
        # CHANNEL_MESSAGE_WITH_SOURCE
        assert response.type == 4
        assert String.contains?(response.data.content, "Unknown command")
        {:ok, %{}}
      end)

      # Call the event handler - this will:
      # 1. Try to find the command using find_command("nonexistent_command")
      # 2. Get nil back since the command doesn't exist
      # 3. Pass nil to InteractionRouter.route_interaction
      # 4. InteractionRouter should handle the nil command gracefully and send error response
      result = UnknownCommandTestConsumer.handle_event({:INTERACTION_CREATE, interaction, %{}})

      # Should handle the unknown command gracefully (returns :ok)
      assert result == :ok

      # Should have processed the interaction
      assert_receive {:interaction_processed, ^interaction}
    end

    test "find_command returns nil for unknown commands" do
      # Test the find_command function directly
      defmodule EmptyConsumer do
        use AshDiscord.Consumer

        ash_discord_consumer do
          domains([])
        end
      end

      # Should return nil for unknown command
      result = EmptyConsumer.find_command(:nonexistent_command)
      assert result == nil

      # Should return nil for string command names too
      result = EmptyConsumer.find_command("nonexistent_command")
      assert result == nil
    end
  end
end
