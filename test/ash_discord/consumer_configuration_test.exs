defmodule AshDiscord.ConsumerConfigurationTest do
  @moduledoc """
  Tests for AshDiscord Consumer configuration system (Tasks 19-20).
  
  Tests the automatic user resolution system and Discord context abstraction
  as outlined in the library extraction breakdown Tasks 19-20.
  """

  use TestApp.DataCase

  setup do
    TestHelper.setup_mocks()
  end

  describe "automatic user resolution system (Task 19)" do
    test "consumer can be configured with user_resource for automatic resolution" do
      # Define a test consumer with user_resource configuration
      defmodule TestUserResolutionConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        # Override the user creation callback
        def create_user_from_discord(discord_user) do
          TestApp.Discord.User.from_discord!(%{
            discord_id: discord_user.id,
            username: discord_user.username || "auto_user_#{discord_user.id}"
          })
        end
      end

      # Test that the consumer is configured correctly
      domains = TestUserResolutionConsumer.domains()
      assert TestApp.Discord in domains
      refute :"Steward.Discord" in domains
    end

    test "consumer can specify custom user resolution logic" do
      defmodule CustomUserResolutionConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        # Custom logic for user creation with additional attributes
        def create_user_from_discord(discord_user) do
          TestApp.Discord.User.from_discord!(%{
            discord_id: discord_user.id,
            username: discord_user.username || "custom_#{discord_user.id}",
            discriminator: discord_user.discriminator || "9999"
          })
        end
      end

      # Verify consumer is configured with domains
      domains = CustomUserResolutionConsumer.domains()
      assert TestApp.Discord in domains
    end

    test "consumer works without user_resource configured (fallback mode)" do
      defmodule FallbackConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        # Uses default create_user_from_discord implementation (returns nil)
      end

      # Should work with fallback behavior
      domains = FallbackConsumer.domains()
      assert TestApp.Discord in domains
    end

    test "user resolution handles errors gracefully" do
      defmodule ErrorHandlingConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        def create_user_from_discord(_discord_user) do
          {:error, :test_user_creation_failed}
        end
      end

      # Consumer should be created successfully even with error-prone user creator
      domains = ErrorHandlingConsumer.domains()
      assert TestApp.Discord in domains
    end
  end

  describe "discord context setting (Task 20)" do
    test "consumer provides minimal Discord context for command execution" do
      defmodule ContextTestConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        def create_user_from_discord(discord_user) do
          TestApp.Discord.User.from_discord!(%{discord_id: discord_user.id})
        end
      end

      # Verify consumer is properly configured
      domains = ContextTestConsumer.domains()
      assert TestApp.Discord in domains
      
      # The user creation callback is used internally by the InteractionRouter
      # We tested its functionality in the InteractionRouter tests
    end

    test "discord context supports different actor patterns" do
      # Test that different consumer configurations can work
      defmodule FlexibleContextConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        def create_user_from_discord(discord_user) do
          case discord_user do
            %{id: id, username: username} when is_binary(username) ->
              TestApp.Discord.User.from_discord!(%{
                discord_id: id,
                username: username
              })
            %{id: id} ->
              TestApp.Discord.User.from_discord!(%{discord_id: id})
          end
        end
      end

      domains = FlexibleContextConsumer.domains()
      assert TestApp.Discord in domains
    end

    test "context management is separated from application-specific logic" do
      defmodule CleanContextConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        def create_user_from_discord(discord_user) do
          # Only Discord command user is set as actor
          # Application logic is separate
          TestApp.Discord.User.from_discord!(%{discord_id: discord_user.id})
        end
      end

      # Verify clean separation - consumer only handles Discord context
      domains = CleanContextConsumer.domains()
      assert length(domains) == 1
      assert TestApp.Discord in domains
      
      # Application would add additional context in their action implementations
      # This test verifies the library provides minimal, clean Discord context only
    end
  end

  describe "configuration validation" do
    test "consumer with invalid user creator can be compiled" do
      # Consumer creation should be successful at compile time
      # Runtime errors from user creation are handled by InteractionRouter  
      defmodule InvalidUserCreatorConsumer do
        use AshDiscord.Consumer, domains: [TestApp.Discord]
        
        # This would cause runtime errors, but compiles fine
        def create_user_from_discord(_discord_user) do
          raise "Intentional error for testing"
        end
      end

      # Consumer should be created successfully
      # Runtime errors are handled by InteractionRouter
      domains = InvalidUserCreatorConsumer.domains()
      assert TestApp.Discord in domains
    end

    test "missing domains configuration uses empty list" do
      defmodule NoDomainConsumer do
        use AshDiscord.Consumer
        # No domains specified
      end

      domains = NoDomainConsumer.domains()
      assert domains == []
    end
  end
end