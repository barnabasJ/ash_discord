defmodule AshDiscord.ResponseFormatterTest do
  use ExUnit.Case, async: true

  alias AshDiscord.Command
  alias AshDiscord.ResponseFormatter
  alias AshDiscord.ResponseFormatter.Default

  describe "behavior interface" do
    test "format_response/3 delegates to appropriate formatter callback" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        # Uses default
        formatter: nil
      }

      interaction = %{user: %{id: 123}, guild_id: 456, channel_id: 789}
      result = "Test success"

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{
               type: 4,
               data: %{
                 content: "Test success",
                 flags: 64
               }
             } = response
    end

    test "format_response/3 handles success results" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: nil
      }

      interaction = %{user: %{id: 123}}
      result = {:ok, "Success data"}

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{type: 4, data: %{content: "Success data"}} = response
    end

    test "format_response/3 handles error results" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: nil
      }

      interaction = %{user: %{id: 123}}
      result = {:error, "Test error"}

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{type: 4, data: %{content: "Error: Test error"}} = response
    end

    test "format_response/3 handles validation errors" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: nil
      }

      interaction = %{user: %{id: 123}}

      validation_errors = [
        %{field: :name, message: "is required"},
        %{field: :email, message: "must be valid"}
      ]

      result = {:error, %{errors: validation_errors}}

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{type: 4, data: %{content: content}} = response
      assert content =~ "Validation errors:"
      assert content =~ "name"
      assert content =~ "email"
    end
  end

  describe "get_formatter/1" do
    test "returns configured formatter when specified" do
      command = %Command{formatter: TestFormatter}
      assert ResponseFormatter.get_formatter(command) == TestFormatter
    end

    test "returns default formatter when none specified" do
      command = %Command{formatter: nil}
      assert ResponseFormatter.get_formatter(command) == Default
    end
  end

  describe "build_context/2" do
    test "builds context from interaction and command" do
      command = %Command{name: :test, action: :test_action}

      interaction = %{
        user: %{id: 123},
        guild_id: 456,
        channel_id: 789
      }

      context = ResponseFormatter.build_context(interaction, command)

      assert %{
               interaction: ^interaction,
               command: ^command,
               user_id: 123,
               guild_id: 456,
               channel_id: 789
             } = context
    end

    test "handles interaction with member" do
      command = %Command{name: :test, action: :test_action}

      interaction = %{
        member: %{user: %{id: 456}},
        guild_id: 789,
        channel_id: 101
      }

      context = ResponseFormatter.build_context(interaction, command)

      assert %{user_id: 456} = context
    end

    test "handles interaction without user" do
      command = %Command{name: :test, action: :test_action}
      interaction = %{guild_id: 789, channel_id: 101}

      context = ResponseFormatter.build_context(interaction, command)

      assert %{user_id: nil} = context
    end
  end

  describe "custom formatter integration" do
    defmodule TestCustomFormatter do
      @behaviour AshDiscord.ResponseFormatter

      @impl true
      def format_success(result, _context) do
        %{
          type: 4,
          data: %{
            content: "Custom success: #{inspect(result)}",
            flags: 64
          }
        }
      end

      @impl true
      def format_error(error, _context) do
        %{
          type: 4,
          data: %{
            content: "Custom error: #{error}",
            flags: 64
          }
        }
      end

      @impl true
      def format_validation_errors(errors, _context) do
        error_count = length(errors)

        %{
          type: 4,
          data: %{
            content: "Custom validation: #{error_count} errors",
            flags: 64
          }
        }
      end
    end

    test "uses custom formatter when configured" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: TestCustomFormatter
      }

      interaction = %{user: %{id: 123}}
      result = "test data"

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{
               type: 4,
               data: %{
                 content: "Custom success: \"test data\"",
                 flags: 64
               }
             } = response
    end

    test "custom formatter handles errors" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: TestCustomFormatter
      }

      interaction = %{user: %{id: 123}}
      result = {:error, "test error"}

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{
               type: 4,
               data: %{
                 content: "Custom error: test error",
                 flags: 64
               }
             } = response
    end

    test "custom formatter handles validation errors" do
      command = %Command{
        name: :test_command,
        action: :test_action,
        formatter: TestCustomFormatter
      }

      interaction = %{user: %{id: 123}}

      validation_errors = [
        %{field: :name, message: "is required"},
        %{field: :email, message: "must be valid"}
      ]

      result = {:error, %{errors: validation_errors}}

      response = ResponseFormatter.format_response(result, interaction, command)

      assert %{
               type: 4,
               data: %{
                 content: "Custom validation: 2 errors",
                 flags: 64
               }
             } = response
    end
  end
end
