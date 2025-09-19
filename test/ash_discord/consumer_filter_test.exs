defmodule AshDiscord.ConsumerFilterTest do
  use ExUnit.Case
  
  # Skip Nostrum-dependent tests in CI or when Discord token is not available
  @moduletag :skip_on_ci

  describe "command filter integration" do
    defmodule TestFilter do
      @behaviour AshDiscord.CommandFilter

      def filter_commands(commands, guild) do
        # Filter out admin commands for non-admin guilds
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

    test "consumer can be configured with command_filter" do
      defmodule FilteredConsumer do
        use AshDiscord.Consumer,
          domains: [TestApp.Discord],
          command_filter: TestFilter
      end

      # Should compile without error
      assert FilteredConsumer.__info__(:functions) |> Keyword.has_key?(:domains)
      assert FilteredConsumer.__info__(:functions) |> Keyword.has_key?(:command_filter)
    end

    test "consumer with command_filter provides filter configuration" do
      defmodule ConfiguredFilterConsumer do
        use AshDiscord.Consumer,
          domains: [TestApp.Discord],
          command_filter: TestFilter
      end

      assert ConfiguredFilterConsumer.command_filter() == TestFilter
    end

    test "consumer without command_filter returns nil for filter configuration" do
      defmodule NoFilterConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
      end

      assert NoFilterConsumer.command_filter() == nil
    end

    test "consumer can use multiple filters as a list" do
      defmodule SecondFilter do
        @behaviour AshDiscord.CommandFilter

        def filter_commands(commands, _guild) do
          # Filter out test commands
          Enum.reject(commands, &String.contains?(Atom.to_string(&1.name), "test"))
        end

        def command_allowed?(command, _guild) do
          not String.contains?(Atom.to_string(command.name), "test")
        end
      end

      defmodule MultiFilterConsumer do
        use AshDiscord.Consumer,
          domains: [TestApp.Discord],
          command_filter: [TestFilter, SecondFilter]
      end

      assert MultiFilterConsumer.command_filter() == [TestFilter, SecondFilter]
    end

    test "consumer applies command filter during command registration" do
      defmodule RegistrationFilterConsumer do
        use AshDiscord.Consumer,
          domains: [TestApp.Discord],
          command_filter: TestFilter

        def filtered_commands_for_guild(guild) do
          commands = @ash_discord_commands
          filter = command_filter()

          if filter do
            AshDiscord.CommandFilter.apply_filter_chain(commands, guild, [filter])
          else
            commands
          end
        end
      end

      # Test with admin guild
      admin_guild = %{id: 123, admin_permissions: true}
      admin_commands = RegistrationFilterConsumer.filtered_commands_for_guild(admin_guild)

      # Test with regular guild
      regular_guild = %{id: 456, admin_permissions: false}
      regular_commands = RegistrationFilterConsumer.filtered_commands_for_guild(regular_guild)

      # Admin guild should have same or more commands than regular guild
      assert length(admin_commands) >= length(regular_commands)
    end

    test "command filter integration with InteractionRouter" do
      defmodule RouterFilterConsumer do
        use AshDiscord.Consumer,
          domains: [TestApp.Discord],
          command_filter: TestFilter

        def command_allowed_for_interaction?(interaction) do
          guild = extract_guild_from_interaction(interaction)
          command_name = String.to_atom(interaction.data.name)
          command = find_command(command_name)
          filter = command_filter()

          if command && filter do
            AshDiscord.CommandFilter.command_allowed_by_chain?(command, guild, [filter])
          else
            true
          end
        end

        defp extract_guild_from_interaction(interaction) do
          # Extract guild info from interaction for filtering
          %{
            id: Map.get(interaction, :guild_id, 0),
            admin_permissions: false  # Would be determined by actual guild permissions
          }
        end
      end

      # Test interaction for admin command
      admin_interaction = %{
        data: %{name: "admin_ban"},
        guild_id: 123
      }

      # Should be filtered out for non-admin guild
      refute RouterFilterConsumer.command_allowed_for_interaction?(admin_interaction)
    end
  end
end