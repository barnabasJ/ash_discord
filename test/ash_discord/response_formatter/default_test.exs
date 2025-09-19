defmodule AshDiscord.ResponseFormatter.DefaultTest do
  use ExUnit.Case, async: true

  alias AshDiscord.ResponseFormatter.Default
  alias AshDiscord.Command

  # Helper struct for testing
  defmodule TestStruct do
    defstruct [:id, :name]
  end

  describe "format_success/2" do
    test "formats struct results" do
      context = %{command: %Command{action: :create}}
      result = %TestStruct{id: 1, name: "test"}

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: "create completed successfully!",
          flags: 64
        }
      } = response
    end

    test "formats list results" do
      context = %{command: %Command{action: :list}}
      result = [%{id: 1}, %{id: 2}, %{id: 3}]

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: "Found 3 items",
          flags: 64
        }
      } = response
    end

    test "formats binary results" do
      context = %{command: %Command{action: :custom}}
      result = "Custom response message"

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: "Custom response message",
          flags: 64
        }
      } = response
    end

    test "formats message move results" do
      context = %{command: %Command{action: :analyze_messages}}
      result = %{
        total_found: 5,
        related_messages: [
          %{
            message: %{
              author: %{discord_username: "user1"},
              content: "This is a test message with some content"
            },
            content_preview: "This is a test message"
          },
          %{
            message: %{
              author: %{discord_username: "user2"},
              content: "Another message"
            },
            content_preview: "Another message"
          }
        ],
        search_parameters: %{single_message: false}
      }

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Found 5 messages in conversation thread"
      assert content =~ "**user1**: This is a test message"
      assert content =~ "**user2**: Another message"
      assert content =~ "and 3 more"
    end

    test "formats message move results for single message" do
      context = %{command: %Command{action: :analyze_messages}}
      result = %{
        total_found: 1,
        related_messages: [
          %{
            message: %{
              author: %{discord_username: "user1"},
              content: "Single message"
            },
            content_preview: "Single message"
          }
        ],
        search_parameters: %{single_message: true}
      }

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Found 1 message in single message"
      refute content =~ "and"
    end

    test "formats message move results with missing author" do
      context = %{command: %Command{action: :analyze_messages}}
      result = %{
        total_found: 1,
        related_messages: [
          %{
            message: %{
              author: nil,
              content: "Message without author"
            },
            content_preview: "Message without author"
          }
        ],
        search_parameters: %{single_message: true}
      }

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "**Unknown**: Message without author"
    end

    test "formats message move results with long content" do
      context = %{command: %Command{action: :analyze_messages}}
      long_content = String.duplicate("a", 150)
      result = %{
        total_found: 1,
        related_messages: [
          %{
            message: %{
              author: %{discord_username: "user1"},
              content: long_content
            },
            content_preview: "Preview text"
          }
        ],
        search_parameters: %{single_message: true}
      }

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Preview text..."
    end

    test "formats generic map results" do
      context = %{command: %Command{action: :update}}
      result = %{updated: true, id: 1}

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: "update completed successfully!",
          flags: 64
        }
      } = response
    end

    test "formats other results as generic success" do
      context = %{command: %Command{action: :custom}}
      result = :ok

      response = Default.format_success(result, context)

      assert %{
        type: 4,
        data: %{
          content: "Command completed successfully!",
          flags: 64
        }
      } = response
    end
  end

  describe "format_error/2" do
    test "formats binary errors" do
      context = %{command: %Command{}}
      error = "Something went wrong"

      response = Default.format_error(error, context)

      assert %{
        type: 4,
        data: %{
          content: "Error: Something went wrong",
          flags: 64
        }
      } = response
    end

    test "formats Ash.Error.Invalid" do
      context = %{command: %Command{}}
      error = %Ash.Error.Invalid{errors: []}

      response = Default.format_error(error, context)

      assert %{
        type: 4,
        data: %{
          content: "Error: Invalid input provided",
          flags: 64
        }
      } = response
    end

    test "formats Ash.Error.Forbidden" do
      context = %{command: %Command{}}
      error = %Ash.Error.Forbidden{errors: []}

      response = Default.format_error(error, context)

      assert %{
        type: 4,
        data: %{
          content: "Error: You don't have permission to perform this action",
          flags: 64
        }
      } = response
    end

    test "formats errors with message field" do
      context = %{command: %Command{}}
      error = %{message: "Custom error message"}

      response = Default.format_error(error, context)

      assert %{
        type: 4,
        data: %{
          content: "Error: Custom error message",
          flags: 64
        }
      } = response
    end

    test "formats unknown errors" do
      context = %{command: %Command{}}
      error = :unknown_error

      response = Default.format_error(error, context)

      assert %{
        type: 4,
        data: %{
          content: "Error: Command failed to execute",
          flags: 64
        }
      } = response
    end
  end

  describe "format_validation_errors/2" do
    test "formats validation errors with field and message" do
      context = %{command: %Command{}}
      errors = [
        %{field: :name, message: "is required"},
        %{field: :email, message: "must be valid"}
      ]

      response = Default.format_validation_errors(errors, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Validation errors:"
      assert content =~ "• name: is required"
      assert content =~ "• email: must be valid"
    end

    test "formats validation errors with only message" do
      context = %{command: %Command{}}
      errors = [
        %{message: "General validation error"},
        %{message: "Another error"}
      ]

      response = Default.format_validation_errors(errors, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Validation errors:"
      assert content =~ "• General validation error"
      assert content =~ "• Another error"
    end

    test "formats binary validation errors" do
      context = %{command: %Command{}}
      errors = ["Error 1", "Error 2"]

      response = Default.format_validation_errors(errors, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Validation errors:"
      assert content =~ "• Error 1"
      assert content =~ "• Error 2"
    end

    test "formats unknown validation errors" do
      context = %{command: %Command{}}
      errors = [:unknown_error, %{unexpected: "format"}]

      response = Default.format_validation_errors(errors, context)

      assert %{
        type: 4,
        data: %{
          content: content,
          flags: 64
        }
      } = response

      assert content =~ "Validation errors:"
      assert content =~ "• :unknown_error"
      assert content =~ "• %{unexpected: \"format\"}"
    end

    test "handles non-list validation errors" do
      context = %{command: %Command{}}
      errors = "Not a list"

      response = Default.format_validation_errors(errors, context)

      assert %{
        type: 4,
        data: %{
          content: "Validation errors:\nInvalid input provided",
          flags: 64
        }
      } = response
    end
  end

end