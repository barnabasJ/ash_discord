defmodule AshDiscord.DslTest do
  use ExUnit.Case

  alias TestApp.Discord
  alias AshDiscord.Info

  describe "DSL compilation and validation" do
    test "domain compiles with AshDiscord extension" do
      # Verify domain can be compiled
      assert {:module, Discord} = Code.ensure_compiled(Discord)
    end

    test "commands are registered correctly" do
      commands = Info.discord_commands(Discord)

      assert length(commands) == 7

      command_names = commands |> Enum.map(& &1.name) |> Enum.sort()

      assert command_names == [
               :admin_ban,
               :configure,
               :create_message,
               :echo,
               :hello,
               :ping,
               :search
             ]
    end

    test "hello command has correct structure" do
      commands = Info.discord_commands(Discord)
      hello_cmd = Enum.find(commands, &(&1.name == :hello))

      assert hello_cmd.name == :hello
      assert hello_cmd.resource == TestApp.Discord.Message
      assert hello_cmd.action == :hello
      assert hello_cmd.description == "A simple hello command"
      assert hello_cmd.options == []
    end

    test "create_message command has correct structure" do
      commands = Info.discord_commands(Discord)
      create_cmd = Enum.find(commands, &(&1.name == :create_message))

      assert create_cmd.name == :create_message
      assert create_cmd.resource == TestApp.Discord.Message
      assert create_cmd.action == :create
      assert create_cmd.description == "Create a message with content"
      # Options should be auto-detected from action
      assert is_list(create_cmd.options)
    end

    test "search command has manual options" do
      commands = Info.discord_commands(Discord)
      search_cmd = Enum.find(commands, &(&1.name == :search))

      assert search_cmd.name == :search
      assert search_cmd.resource == TestApp.Discord.Message
      assert search_cmd.action == :search

      options = search_cmd.options
      assert length(options) == 2

      query_option = Enum.find(options, &(&1.name == :query))
      assert query_option.type == :string
      assert query_option.required == true
      assert query_option.description == "Search query"

      limit_option = Enum.find(options, &(&1.name == :limit))
      assert limit_option.type == :integer
      assert limit_option.required == false
      assert limit_option.description == "Number of results"
    end

    test "configure command has manual options" do
      commands = Info.discord_commands(Discord)
      config_cmd = Enum.find(commands, &(&1.name == :configure))

      assert config_cmd.name == :configure
      assert config_cmd.resource == TestApp.Discord.Guild
      assert config_cmd.action == :configure

      options = config_cmd.options
      assert length(options) == 2

      setting_option = Enum.find(options, &(&1.name == :setting))
      assert setting_option.type == :string
      assert setting_option.required == true

      enabled_option = Enum.find(options, &(&1.name == :enabled))
      assert enabled_option.type == :boolean
      assert enabled_option.required == true
    end
  end

  describe "command registry integration" do
    test "commands can be collected by registry" do
      # This would normally be tested with actual Discord API
      # For now, just verify the commands are accessible
      commands = Info.discord_commands(Discord)

      for command <- commands do
        assert is_atom(command.name)
        assert is_atom(command.resource)
        assert is_atom(command.action)
        assert is_binary(command.description)
        assert is_list(command.options)
      end
    end
  end
end
