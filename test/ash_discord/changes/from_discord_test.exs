defmodule AshDiscord.Changes.FromDiscordTest do
  use ExUnit.Case, async: true

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Changes.FromDiscord

  describe "init/1" do
    test "accepts valid Discord entity types" do
      valid_types = [
        :user,
        :guild,
        :guild_member,
        :role,
        :channel,
        :message,
        :emoji,
        :voice_state,
        :webhook,
        :invite,
        :message_attachment,
        :message_reaction,
        :typing_indicator,
        :sticker,
        :interaction
      ]

      for type <- valid_types do
        assert {:ok, [type: ^type]} = FromDiscord.init(type: type)
      end
    end

    test "rejects invalid Discord entity types" do
      invalid_types = [:invalid_type, :not_supported, :random]

      for type <- invalid_types do
        assert_raise ArgumentError, ~r/Invalid Discord entity type/, fn ->
          FromDiscord.init(type: type)
        end
      end
    end

    test "requires type option" do
      assert_raise KeyError, fn ->
        FromDiscord.init([])
      end
    end
  end

  describe "type-independent behavior" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.user_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
      assert error_message =~ "is invalid"
    end

    test "API fallback handles unsupported entity types" do
      # Voice states don't support API fallback since Discord doesn't provide REST endpoints for them
      # They require discord_struct argument and only work with struct-first pattern
      result = TestApp.Discord.voice_state_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "argument discord_struct is required"
    end

    test "API fallback requires discord_id for supported types" do
      # Call user action without discord_id or discord_struct
      result = TestApp.Discord.user_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for user entity"
    end

    test "API fallback works when no discord_struct provided" do
      # Create a mock that will be called by the API fetcher
      Mimic.copy(Nostrum.Api.User)

      # Mock successful API response
      Mimic.expect(Nostrum.Api.User, :get, fn 999_888_777 ->
        {:ok, user(%{id: 999_888_777, username: "api_fetched_user"})}
      end)

      # Call action without discord_struct, providing only discord_id
      result = TestApp.Discord.user_from_discord(%{discord_id: 999_888_777})

      assert {:ok, created_user} = result
      assert created_user.discord_id == 999_888_777
      assert created_user.discord_username == "api_fetched_user"
      assert created_user.email == "discord+999888777@discord.local"
    end

    test "API fallback handles API errors gracefully" do
      Mimic.copy(Nostrum.Api.User)

      # Mock API error response
      Mimic.expect(Nostrum.Api.User, :get, fn 999_888_777 ->
        {:error, %{status_code: 404, message: "User not found"}}
      end)

      # Call action without discord_struct
      result = TestApp.Discord.user_from_discord(%{discord_id: 999_888_777})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch user with ID 999888777"
    end

    test "Guild API fallback works correctly" do
      Mimic.copy(Nostrum.Api.Guild)

      # Mock successful guild API response
      Mimic.expect(Nostrum.Api.Guild, :get, fn 888_777_666 ->
        {:ok, guild(%{id: 888_777_666, name: "API Fetched Guild"})}
      end)

      # Call action without discord_struct
      result = TestApp.Discord.guild_from_discord(%{discord_id: 888_777_666})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == 888_777_666
      assert created_guild.name == "API Fetched Guild"
    end
  end
end
