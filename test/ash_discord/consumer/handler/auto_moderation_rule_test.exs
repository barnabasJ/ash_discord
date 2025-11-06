defmodule AshDiscord.Consumer.Handler.AutoModerationRuleTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.AutoModerationRule
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates auto moderation rule in database" do
      guild = guild()
      creator = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: creator}, authorize?: false)

      rule_data = auto_moderation_rule(%{guild_id: guild.id, creator_id: creator.id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRule,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      {:ok, rule_payload} = Payloads.AutoModerationRule.new(rule_data)

      assert :ok = AutoModerationRule.create(rule_payload, %Nostrum.Struct.WSState{}, context)

      assert [created_rule] = TestApp.Discord.AutoModerationRule.read!(authorize?: false)

      assert created_rule.discord_id == rule_data.id
      assert created_rule.name == rule_data.name
      assert created_rule.guild_discord_id == rule_data.guild_id
      assert created_rule.creator_discord_id == rule_data.creator_id
      assert created_rule.event_type == rule_data.event_type
      assert created_rule.trigger_type == rule_data.trigger_type
      assert created_rule.enabled == rule_data.enabled
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing auto moderation rule in database" do
      guild = guild()
      creator = user()

      rule =
        auto_moderation_rule(%{
          name: "old-name",
          enabled: false,
          guild_id: guild.id,
          creator_id: creator.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: creator}, authorize?: false)
      TestApp.Discord.auto_moderation_rule_from_discord!(%{data: rule}, authorize?: false)

      new_rule =
        auto_moderation_rule(%{
          id: rule.id,
          guild_id: guild.id,
          creator_id: creator.id,
          name: "new-name",
          enabled: true
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRule,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      new_rule_payload = Payloads.AutoModerationRule.new!(new_rule)

      assert :ok = AutoModerationRule.update(new_rule_payload, %Nostrum.Struct.WSState{}, context)

      assert [updated_rule] = TestApp.Discord.AutoModerationRule.read!(authorize?: false)

      assert updated_rule.discord_id == new_rule.id
      assert updated_rule.name == "new-name"
      assert updated_rule.enabled == true
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes auto moderation rule from database" do
      guild = guild()
      creator = user()

      rule =
        auto_moderation_rule(%{
          name: "old-name",
          enabled: false,
          guild_id: guild.id,
          creator_id: creator.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: creator}, authorize?: false)
      TestApp.Discord.auto_moderation_rule_from_discord!(%{data: rule}, authorize?: false)

      rule_payload =
        auto_moderation_rule(%{
          id: rule.id,
          guild_id: guild.id,
          creator_id: creator.id,
          name: "new-name",
          enabled: true
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRule,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      assert :ok = AutoModerationRule.delete(rule_payload, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.AutoModerationRule.read!(authorize?: false)
    end

    test "handles missing auto moderation rule gracefully" do
      rule_data = auto_moderation_rule()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRule,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      {:ok, rule_payload} = Payloads.AutoModerationRule.new(rule_data)

      assert :ok = AutoModerationRule.delete(rule_payload, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "execute/3" do
    @tag :fixed
    test "creates auto moderation rule execution event in database" do
      guild = guild()
      user = user()
      guild_member = guild_member(%{guild_id: guild.id, user_id: user.id})
      channel = channel(%{guild_id: guild.id})

      message =
        message(%{guild_id: guild.id, author: user, member: guild_member, channel_id: channel.id})

      rule = auto_moderation_rule(%{guild_id: guild.id, creator_id: user.id})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)
      TestApp.Discord.guild_member_from_discord!(%{data: guild_member}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message}, authorize?: false)

      TestApp.Discord.auto_moderation_rule_from_discord!(%{data: rule}, authorize?: false)

      execute_attrs =
        %{
          user_id: user.id,
          guild_id: guild.id,
          message_id: message.id,
          channel_id: channel.id,
          rule_id: rule.id
        }

      execute_data = auto_moderation_rule_execute(execute_attrs)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRuleExecute,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      {:ok, execute_payload} = Payloads.AutoModerationRuleExecute.new(execute_data)

      assert :ok =
               AutoModerationRule.execute(
                 execute_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_execution] = TestApp.Discord.AutoModerationRuleExecute.read!(authorize?: false)

      assert created_execution.guild_discord_id == execute_data.guild_id
      assert created_execution.rule_discord_id == execute_data.rule_id
      assert created_execution.user_discord_id == execute_data.user_id
      assert created_execution.content == execute_data.content
      assert created_execution.matched_keyword == execute_data.matched_keyword
      assert created_execution.matched_content == execute_data.matched_content
    end

    @tag :fixed
    test "handles optional fields in execution event" do
      guild = guild()
      user = user()
      rule = auto_moderation_rule(%{guild_id: guild.id, creator_id: user.id})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)
      TestApp.Discord.auto_moderation_rule_from_discord!(%{data: rule}, authorize?: false)

      execute_data =
        auto_moderation_rule_execute(%{
          guild_id: guild.id,
          user_id: user.id,
          rule_id: rule.id,
          channel_id: nil,
          message_id: nil,
          alert_system_message_id: nil,
          matched_keyword: nil,
          matched_content: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.AutoModerationRuleExecute,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      {:ok, execute_payload} = Payloads.AutoModerationRuleExecute.new(execute_data)

      assert :ok = AutoModerationRule.execute(execute_payload, %Nostrum.Struct.WSState{}, context)

      [created_execution] = TestApp.Discord.AutoModerationRuleExecute.read!()

      assert created_execution.guild_discord_id == execute_data.guild_id
      assert created_execution.rule_discord_id == execute_data.rule_id
      assert created_execution.user_discord_id == execute_data.user_id
      assert created_execution.channel_discord_id == nil
      assert created_execution.message_discord_id == nil
      assert created_execution.matched_keyword == nil
    end
  end
end
