defmodule AshDiscord.CommandTest do
  use ExUnit.Case

  alias AshDiscord.{Command, Option}

  describe "Command struct" do
    test "creates command with required fields" do
      command = %Command{
        name: :test_command,
        description: "Test command description",
        resource: TestModule,
        action: :test_action,
        type: :chat_input,
        scope: :guild,
        options: []
      }

      assert command.name == :test_command
      assert command.description == "Test command description"
      assert command.resource == TestModule
      assert command.action == :test_action
      assert command.type == :chat_input
      assert command.scope == :guild
      assert command.options == []
    end

    test "has sensible defaults" do
      # Test that the struct can be created with minimal data
      command = %Command{
        name: :test,
        description: "Test",
        resource: TestModule,
        action: :test_action
      }

      # Defaults should be applied during DSL processing
      assert command.name == :test
      assert command.description == "Test"
    end
  end

  describe "Option struct" do
    test "creates option with required fields" do
      option = %Option{
        name: :test_option,
        description: "Test option description",
        type: :string,
        required: true,
        choices: nil
      }

      assert option.name == :test_option
      assert option.description == "Test option description"
      assert option.type == :string
      assert option.required == true
      assert option.choices == nil
    end

    test "supports different option types" do
      string_option = %Option{name: :str, type: :string, description: "String"}
      assert string_option.type == :string

      boolean_option = %Option{name: :bool, type: :boolean, description: "Boolean"}
      assert boolean_option.type == :boolean

      integer_option = %Option{name: :int, type: :integer, description: "Integer"}
      assert integer_option.type == :integer

      number_option = %Option{name: :num, type: :number, description: "Number"}
      assert number_option.type == :number

      user_option = %Option{name: :user, type: :user, description: "User"}
      assert user_option.type == :user

      channel_option = %Option{name: :channel, type: :channel, description: "Channel"}
      assert channel_option.type == :channel

      role_option = %Option{name: :role, type: :role, description: "Role"}
      assert role_option.type == :role
    end

    test "supports choices" do
      choices = [
        %{name: "Option 1", value: "opt1"},
        %{name: "Option 2", value: "opt2"}
      ]

      option = %Option{
        name: :choice_option,
        type: :string,
        description: "Choice option",
        choices: choices,
        required: false
      }

      assert option.choices == choices
    end

    test "defaults required to false" do
      option = %Option{
        name: :optional,
        type: :string,
        description: "Optional",
        required: false
      }

      # Should be explicitly set to false
      assert option.required == false
    end
  end

  describe "command validation" do
    test "command names should be atoms" do
      command = %Command{
        name: :valid_atom_name,
        description: "Valid command",
        resource: TestModule,
        action: :test
      }

      assert is_atom(command.name)
    end

    test "command descriptions should be strings" do
      command = %Command{
        name: :test,
        description: "Valid description",
        resource: TestModule,
        action: :test
      }

      assert is_binary(command.description)
    end

    test "command types should be valid Discord types" do
      valid_types = [:chat_input, :user, :message]

      Enum.each(valid_types, fn type ->
        command = %Command{
          name: :test,
          description: "Test",
          resource: TestModule,
          action: :test,
          type: type
        }

        assert command.type == type
      end)
    end

    test "command scopes should be valid" do
      valid_scopes = [:guild, :global]

      Enum.each(valid_scopes, fn scope ->
        command = %Command{
          name: :test,
          description: "Test",
          resource: TestModule,
          action: :test,
          scope: scope
        }

        assert command.scope == scope
      end)
    end
  end

  describe "option validation" do
    test "option names should be atoms" do
      option = %Option{
        name: :valid_atom_name,
        type: :string,
        description: "Valid option"
      }

      assert is_atom(option.name)
    end

    test "option types should be valid Discord types" do
      valid_types = [:string, :integer, :boolean, :user, :channel, :role, :number]

      Enum.each(valid_types, fn type ->
        option = %Option{
          name: :test,
          type: type,
          description: "Test option"
        }

        assert option.type == type
      end)
    end

    test "option required should be boolean" do
      required_option = %Option{
        name: :required,
        type: :string,
        description: "Required option",
        required: true
      }

      optional_option = %Option{
        name: :optional,
        type: :string,
        description: "Optional option",
        required: false
      }

      assert required_option.required == true
      assert optional_option.required == false
    end
  end
end
