defmodule AshDiscord.CommandFilterTest do
  use ExUnit.Case

  describe "behavior implementation" do
    defmodule TestFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, guild) do
        # Filter out commands with "admin" in the name if guild has no admin permissions
        if Map.get(guild, :admin_permissions, false) do
          commands
        else
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "admin"))
        end
      end

      def command_allowed?(command, guild) do
        # Same logic as filter_commands but for individual command checks
        if String.contains?(Atom.to_string(command.name), "admin") do
          Map.get(guild, :admin_permissions, false)
        else
          true
        end
      end
    end

    test "filter_commands filters admin commands for non-admin guilds" do
      commands = [
        %{name: :chat, description: "Start a chat"},
        %{name: :admin_ban, description: "Ban a user"},
        %{name: :help, description: "Get help"}
      ]

      guild = %{id: 123, admin_permissions: false}

      filtered = TestFilter.filter_commands(commands, guild)

      assert length(filtered) == 2
      assert Enum.find(filtered, &(&1.name == :chat))
      assert Enum.find(filtered, &(&1.name == :help))
      refute Enum.find(filtered, &(&1.name == :admin_ban))
    end

    test "filter_commands allows all commands for admin guilds" do
      commands = [
        %{name: :chat, description: "Start a chat"},
        %{name: :admin_ban, description: "Ban a user"},
        %{name: :help, description: "Get help"}
      ]

      guild = %{id: 123, admin_permissions: true}

      filtered = TestFilter.filter_commands(commands, guild)

      assert length(filtered) == 3
      assert Enum.find(filtered, &(&1.name == :chat))
      assert Enum.find(filtered, &(&1.name == :help))
      assert Enum.find(filtered, &(&1.name == :admin_ban))
    end

    test "command_allowed? returns true for non-admin commands" do
      command = %{name: :chat, description: "Start a chat"}
      guild = %{id: 123, admin_permissions: false}

      assert TestFilter.command_allowed?(command, guild)
    end

    test "command_allowed? returns false for admin commands in non-admin guilds" do
      command = %{name: :admin_ban, description: "Ban a user"}
      guild = %{id: 123, admin_permissions: false}

      refute TestFilter.command_allowed?(command, guild)
    end

    test "command_allowed? returns true for admin commands in admin guilds" do
      command = %{name: :admin_ban, description: "Ban a user"}
      guild = %{id: 123, admin_permissions: true}

      assert TestFilter.command_allowed?(command, guild)
    end
  end
end
