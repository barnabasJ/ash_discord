defmodule AshDiscord.Test.Generators.Discord.VerificationTest do
  @moduledoc """
  Verification tests for critical Discord generator fixes.
  These tests verify the corrections made based on GENERATOR_VERIFICATION.md
  """
  use ExUnit.Case
  import AshDiscord.Test.Generators.Discord

  describe "member generator - DateTime fields" do
    test "joined_at is DateTime, not Unix timestamp" do
      member = member()
      assert %DateTime{} = member.joined_at
    end

    test "premium_since is DateTime when present" do
      # Generate multiple members to get one with premium_since
      members = for _ <- 1..20, do: member()
      premium_members = Enum.filter(members, & &1.premium_since)

      if Enum.any?(premium_members) do
        Enum.each(premium_members, fn m ->
          assert %DateTime{} = m.premium_since
        end)
      end
    end

    test "communication_disabled_until is DateTime when present" do
      # Generate multiple members to get one with timeout
      members = for _ <- 1..50, do: member()
      timed_out = Enum.filter(members, & &1.communication_disabled_until)

      if Enum.any?(timed_out) do
        Enum.each(timed_out, fn m ->
          assert %DateTime{} = m.communication_disabled_until
        end)
      end
    end

    test "flags field is present" do
      member = member()
      assert is_integer(member.flags)
    end
  end

  describe "sticker generator - Enum atoms" do
    test "type is atom, not integer" do
      sticker = sticker()
      assert sticker.type in [:standard, :guild]
    end

    test "format_type is atom, not integer" do
      sticker = sticker()
      assert sticker.format_type in [:png, :apng, :lottie, :gif]
    end
  end

  describe "message generator - DateTime fields" do
    test "timestamp is DateTime, not ISO8601 string" do
      message = message()
      assert %DateTime{} = message.timestamp
    end

    test "edited_timestamp is DateTime when present" do
      # Generate multiple messages to get one with edited_timestamp
      messages = for _ <- 1..20, do: message()
      edited = Enum.filter(messages, & &1.edited_timestamp)

      if Enum.any?(edited) do
        Enum.each(edited, fn m ->
          assert %DateTime{} = m.edited_timestamp
        end)
      end
    end

    test "edited_timestamp is after original timestamp when present" do
      messages = for _ <- 1..20, do: message()
      edited = Enum.filter(messages, & &1.edited_timestamp)

      if Enum.any?(edited) do
        Enum.each(edited, fn m ->
          assert DateTime.compare(m.edited_timestamp, m.timestamp) == :gt
        end)
      end
    end
  end

  describe "message generator - member field" do
    test "member field is present for guild messages" do
      messages = for _ <- 1..10, do: message()
      guild_messages = Enum.filter(messages, & &1.guild_id)

      # Should have some guild messages (80% probability)
      assert Enum.any?(guild_messages)

      Enum.each(guild_messages, fn m ->
        assert %Nostrum.Struct.Guild.Member{} = m.member
        assert m.member.user_id == m.author.id
      end)
    end

    test "member field is nil for DM messages" do
      messages = for _ <- 1..10, do: message()
      dm_messages = Enum.filter(messages, &is_nil(&1.guild_id))

      # Should have some DM messages (20% probability)
      if Enum.any?(dm_messages) do
        Enum.each(dm_messages, fn m ->
          assert is_nil(m.member)
        end)
      end
    end
  end

  describe "interaction generator - member field" do
    test "member field is proper Member struct" do
      interaction = interaction()
      assert %Nostrum.Struct.Guild.Member{} = interaction.member
      assert interaction.member.user_id == interaction.user.id
    end

    test "member has all required DateTime fields" do
      interaction = interaction()
      assert %DateTime{} = interaction.member.joined_at
    end
  end

  describe "message_reaction generator - emoji field" do
    test "emoji field is Emoji struct, not plain map" do
      reaction = message_reaction()
      assert %Nostrum.Struct.Emoji{} = reaction.emoji
    end

    test "emoji struct has all required fields for unicode emoji" do
      # Generate multiple reactions to get unicode emoji
      reactions = for _ <- 1..10, do: message_reaction()
      unicode = Enum.filter(reactions, &is_nil(&1.emoji.id))

      if Enum.any?(unicode) do
        Enum.each(unicode, fn r ->
          assert %Nostrum.Struct.Emoji{} = r.emoji
          assert is_nil(r.emoji.id)
          assert is_binary(r.emoji.name)
          assert r.emoji.animated == false
          assert is_boolean(r.emoji.managed)
        end)
      end
    end

    test "emoji struct has all required fields for custom emoji" do
      # Generate multiple reactions to get custom emoji
      reactions = for _ <- 1..10, do: message_reaction()
      custom = Enum.filter(reactions, & &1.emoji.id)

      if Enum.any?(custom) do
        Enum.each(custom, fn r ->
          assert %Nostrum.Struct.Emoji{} = r.emoji
          assert is_integer(r.emoji.id)
          assert is_binary(r.emoji.name)
          assert is_boolean(r.emoji.animated)
          assert is_boolean(r.emoji.managed)
        end)
      end
    end
  end
end
