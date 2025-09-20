defmodule AshDiscord.Changes.FromDiscord.UserTest do
  use ExUnit.Case, async: true

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Changes.FromDiscord

  @tag :focus
  describe "transform_user/2" do
    test "transforms Discord user with basic attributes" do
      user_struct =
        user(%{
          id: 123_456_789,
          username: "testuser",
          avatar: "avatar_hash123"
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify transformations once implementation is complete
      # Should test:
      # - discord_id mapped from id
      # - discord_username mapped from username
      # - discord_avatar mapped from avatar
      # - email generated in format "discord+#{discord_id}@{domain}"
      assert %Ash.Changeset{} = result
    end

    test "transforms Discord user with all attributes" do
      user_struct =
        user(%{
          id: 987_654_321,
          username: "fulluser",
          discriminator: "1234",
          global_name: "Full User",
          avatar: "full_avatar_hash",
          bot: false,
          public_flags: 128
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify all user attribute transformations
      assert %Ash.Changeset{} = result
    end

    test "handles user with nil avatar" do
      user_struct =
        user(%{
          id: 456_789_123,
          username: "noavatar",
          avatar: nil
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify nil avatar is handled gracefully
      assert %Ash.Changeset{} = result
    end

    test "generates Discord email with correct format" do
      user_struct =
        user(%{
          id: 555_666_777,
          username: "emailtest"
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify email format: "discord+555666777@discord.local"
      assert %Ash.Changeset{} = result
    end

    test "handles bot users correctly" do
      user_struct =
        user(%{
          id: 111_222_333,
          username: "TestBot",
          bot: true
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify bot users are processed the same way as regular users
      assert %Ash.Changeset{} = result
    end

    test "handles user with empty username" do
      user_struct =
        user(%{
          id: 888_999_000,
          username: ""
        })

      changeset = build_user_changeset(user_struct)
      opts = [type: :user]

      result = FromDiscord.change(changeset, opts, %{})

      # TODO: Verify empty username handling
      assert %Ash.Changeset{} = result
    end
  end

  # Test helper functions
  defp build_user_changeset(user_struct) do
    %Ash.Changeset{
      resource: UserFromDiscordTestResource,
      action_type: :create,
      action: :from_discord,
      arguments: %{discord_struct: user_struct},
      attributes: %{},
      errors: [],
      valid?: true
    }
  end

  # Test resource matching expected User resource structure
  defmodule UserFromDiscordTestResource do
    @moduledoc false
    use Ash.Resource, domain: nil

    attributes do
      uuid_primary_key :id
      attribute :discord_id, :string
      attribute :discord_username, :string
      attribute :discord_avatar, :string
      attribute :email, :string
      attribute :discriminator, :string
    end

    actions do
      defaults [:read, :update, :destroy]

      create :from_discord do
        argument :discord_struct, :map, description: "Discord user struct to transform"
      end
    end
  end
end
