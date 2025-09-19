defmodule AshDiscord.CommandFilterTest do
  use ExUnit.Case
  alias AshDiscord.CommandFilter

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

  describe "filter chain" do
    defmodule FirstFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, _guild) do
        # Filter out test commands
        Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "test"))
      end

      def command_allowed?(command, _guild) do
        not String.contains?(Atom.to_string(command.name), "test")
      end
    end

    defmodule SecondFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, _guild) do
        # Filter out commands with numbers
        Enum.reject(commands, &(&1.name |> Atom.to_string() |> String.match?(~r/\d/)))
      end

      def command_allowed?(command, _guild) do
        not (command.name |> Atom.to_string() |> String.match?(~r/\d/))
      end
    end

    test "apply_filter_chain applies multiple filters in sequence" do
      commands = [
        %{name: :chat, description: "Start a chat"},
        %{name: :test_command, description: "Test command"},
        %{name: :help2, description: "Help version 2"},
        %{name: :admin, description: "Admin command"}
      ]

      guild = %{id: 123}
      filters = [FirstFilter, SecondFilter]

      filtered = CommandFilter.apply_filter_chain(commands, guild, filters)

      # Should filter out :test_command (FirstFilter) and :help2 (SecondFilter)
      assert length(filtered) == 2
      assert Enum.find(filtered, &(&1.name == :chat))
      assert Enum.find(filtered, &(&1.name == :admin))
      refute Enum.find(filtered, &(&1.name == :test_command))
      refute Enum.find(filtered, &(&1.name == :help2))
    end

    test "apply_filter_chain with empty filter list returns original commands" do
      commands = [%{name: :chat, description: "Start a chat"}]
      guild = %{id: 123}

      filtered = CommandFilter.apply_filter_chain(commands, guild, [])

      assert filtered == commands
    end

    test "apply_filter_chain with nil filters returns original commands" do
      commands = [%{name: :chat, description: "Start a chat"}]
      guild = %{id: 123}

      filtered = CommandFilter.apply_filter_chain(commands, guild, nil)

      assert filtered == commands
    end
  end
end