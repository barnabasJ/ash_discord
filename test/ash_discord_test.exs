defmodule AshDiscordTest do
  use ExUnit.Case, async: true
  use Mimic
  doctest AshDiscord

  setup do
    TestHelper.setup_mocks()
    :ok
  end

  describe "AshDiscord module" do
    test "has version function" do
      version = AshDiscord.version()
      assert is_binary(version)
      assert version == "0.1.0"
    end
  end
end
