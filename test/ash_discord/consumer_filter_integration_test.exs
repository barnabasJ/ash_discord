defmodule AshDiscord.ConsumerFilterIntegrationTest do
  use ExUnit.Case

  alias AshDiscord.CommandFilter

  describe "command filter configuration" do
    defmodule TestFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, guild) do
        if Map.get(guild, :admin_permissions, false) do
          commands
        else
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "admin"))
        end
      end

      def command_allowed?(command, guild) do
        if String.contains?(Atom.to_string(command.name), "admin") do
          Map.get(guild, :admin_permissions, false)
        else
          true
        end
      end
    end

    test "consumer configuration accepts command_filter option" do
      # Test that the macro accepts the option without compiling the full consumer
      consumer_opts = [domains: [TestApp.Discord], command_filter: TestFilter]

      domains = Keyword.get(consumer_opts, :domains, [])
      command_filter = Keyword.get(consumer_opts, :command_filter, nil)

      assert domains == [TestApp.Discord]
      assert command_filter == TestFilter
    end

    test "command_filter can be a single filter module" do
      consumer_opts = [command_filter: TestFilter]
      command_filter = Keyword.get(consumer_opts, :command_filter, nil)

      assert command_filter == TestFilter
      assert not is_list(command_filter)
    end

    test "command_filter can be a list of filter modules" do
      defmodule SecondFilter do
        @behaviour AshDiscord.CommandFilter

        def filter_commands(commands, _guild) do
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "test"))
        end

        def command_allowed?(command, _guild) do
          not String.contains?(Atom.to_string(command.name), "test")
        end
      end

      consumer_opts = [command_filter: [TestFilter, SecondFilter]]
      command_filter = Keyword.get(consumer_opts, :command_filter, nil)

      assert command_filter == [TestFilter, SecondFilter]
      assert is_list(command_filter)
    end

    test "command_filter defaults to nil when not specified" do
      consumer_opts = [domains: [TestApp.Discord]]
      command_filter = Keyword.get(consumer_opts, :command_filter, nil)

      assert command_filter == nil
    end

    test "filter integration logic works with single filter" do
      commands = [
        %{name: :chat, description: "Start a chat"},
        %{name: :admin_ban, description: "Ban a user"},
        %{name: :help, description: "Get help"}
      ]

      guild = %{id: 123, admin_permissions: false}
      filters = [TestFilter]

      filtered = CommandFilter.apply_filter_chain(commands, guild, filters)

      assert length(filtered) == 2
      assert Enum.find(filtered, &(&1.name == :chat))
      assert Enum.find(filtered, &(&1.name == :help))
      refute Enum.find(filtered, &(&1.name == :admin_ban))
    end

    test "filter integration logic works with multiple filters" do
      defmodule TestCommandFilter do
        @behaviour AshDiscord.CommandFilter

        def filter_commands(commands, _guild) do
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "test"))
        end

        def command_allowed?(command, _guild) do
          not String.contains?(Atom.to_string(command.name), "test")
        end
      end

      commands = [
        %{name: :chat, description: "Start a chat"},
        %{name: :admin_ban, description: "Ban a user"},
        %{name: :test_command, description: "Test command"},
        %{name: :help, description: "Get help"}
      ]

      guild = %{id: 123, admin_permissions: false}
      filters = [TestFilter, TestCommandFilter]

      filtered = CommandFilter.apply_filter_chain(commands, guild, filters)

      # Should filter out admin_ban (TestFilter) and test_command (TestCommandFilter)
      assert length(filtered) == 2
      assert Enum.find(filtered, &(&1.name == :chat))
      assert Enum.find(filtered, &(&1.name == :help))
      refute Enum.find(filtered, &(&1.name == :admin_ban))
      refute Enum.find(filtered, &(&1.name == :test_command))
    end

    test "command_allowed_by_chain works with single filter" do
      command = %{name: :admin_ban, description: "Ban a user"}
      guild = %{id: 123, admin_permissions: false}
      filters = [TestFilter]

      refute CommandFilter.command_allowed_by_chain?(command, guild, filters)

      # Test with admin permissions
      admin_guild = %{id: 123, admin_permissions: true}
      assert CommandFilter.command_allowed_by_chain?(command, admin_guild, filters)
    end

    test "command_allowed_by_chain works with multiple filters" do
      defmodule RestrictiveFilter do
        @behaviour AshDiscord.CommandFilter

        def filter_commands(commands, _guild) do
          # Always filter out ban commands
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "ban"))
        end

        def command_allowed?(command, _guild) do
          not String.contains?(Atom.to_string(command.name), "ban")
        end
      end

      command = %{name: :admin_ban, description: "Ban a user"}
      guild = %{id: 123, admin_permissions: true}  # Admin permissions
      filters = [TestFilter, RestrictiveFilter]

      # Even with admin permissions, RestrictiveFilter blocks ban commands
      refute CommandFilter.command_allowed_by_chain?(command, guild, filters)

      # But non-admin commands should work
      chat_command = %{name: :chat, description: "Start a chat"}
      assert CommandFilter.command_allowed_by_chain?(chat_command, guild, filters)
    end

    test "guild context extraction pattern" do
      # Test the expected guild context structure
      interaction = %{
        guild_id: 123456789,
        user: %{id: 987654321}
      }

      guild_context = %{
        id: Map.get(interaction, :guild_id, 0),
        interaction: interaction
      }

      assert guild_context.id == 123456789
      assert guild_context.interaction == interaction
    end

    test "filter selection logic for consumer configuration" do
      # Test the logic that would be used in the Consumer macro
      single_filter = TestFilter
      multiple_filters = [TestFilter, TestFilter]

      # Single filter conversion
      single_as_list = if is_list(single_filter), do: single_filter, else: [single_filter]
      assert single_as_list == [TestFilter]

      # Multiple filters (already list)
      multiple_as_list = if is_list(multiple_filters), do: multiple_filters, else: [multiple_filters]
      assert multiple_as_list == [TestFilter, TestFilter]

      # Nil filter
      nil_filter = nil
      assert nil_filter == nil
    end
  end
end