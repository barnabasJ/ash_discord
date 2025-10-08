defmodule AshDiscord.Consumer.Handler.AutoModerationRuleTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.AutoModerationRule
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    test "creates auto moderation rule in database" do
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

      assert :ok = AutoModerationRule.create(rule_payload, %Nostrum.Struct.WSState{}, context)

      # Verify rule was created in database
      rules = TestApp.Discord.AutoModerationRule.read!()
      assert length(rules) == 1

      created_rule = hd(rules)
      assert created_rule.discord_id == rule_data.id
      assert created_rule.name == rule_data.name
      assert created_rule.guild_id == rule_data.guild_id
      assert created_rule.creator_id == rule_data.creator_id
      assert created_rule.event_type == rule_data.event_type
      assert created_rule.trigger_type == rule_data.trigger_type
      assert created_rule.enabled == rule_data.enabled
    end
  end

  describe "update/3" do
    test "updates existing auto moderation rule in database" do
      rule_id = generate_snowflake()
      _old_rule = auto_moderation_rule(%{id: rule_id, name: "old-name", enabled: false})
      new_rule = auto_moderation_rule(%{id: rule_id, name: "new-name", enabled: true})

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

      {:ok, new_rule_payload} = Payloads.AutoModerationRule.new(new_rule)

      assert :ok = AutoModerationRule.update(new_rule_payload, %Nostrum.Struct.WSState{}, context)

      # Verify rule was updated (upserted) in database
      rules = TestApp.Discord.AutoModerationRule.read!()
      assert length(rules) == 1

      updated_rule = hd(rules)
      assert updated_rule.discord_id == new_rule.id
      assert updated_rule.name == "new-name"
      assert updated_rule.enabled == true
    end
  end

  describe "delete/3" do
    test "deletes auto moderation rule from database" do
      rule_data = auto_moderation_rule()

      # First create the rule
      {:ok, rule_payload} = Payloads.AutoModerationRule.new(rule_data)

      {:ok, _created} =
        TestApp.Discord.AutoModerationRule
        |> Ash.Changeset.for_create(:from_discord, %{
          data: rule_payload
        })
        |> Ash.create()

      # Verify rule exists
      rules_before = TestApp.Discord.AutoModerationRule.read!()
      assert length(rules_before) == 1

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

      # Verify rule was deleted from database
      rules_after = TestApp.Discord.AutoModerationRule.read!()
      assert length(rules_after) == 0
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

      # Should not crash when rule doesn't exist
      assert :ok = AutoModerationRule.delete(rule_payload, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "execute/3" do
    test "creates auto moderation rule execution event in database" do
      execute_data = auto_moderation_rule_execute()

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

      # Verify execution event was created in database
      executions = TestApp.Discord.AutoModerationRuleExecute.read!()
      assert length(executions) == 1

      created_execution = hd(executions)
      assert created_execution.guild_id == execute_data.guild_id
      assert created_execution.rule_id == execute_data.rule_id
      assert created_execution.user_id == execute_data.user_id
      assert created_execution.content == execute_data.content
      assert created_execution.matched_keyword == execute_data.matched_keyword
      assert created_execution.matched_content == execute_data.matched_content
    end

    test "handles optional fields in execution event" do
      execute_data =
        auto_moderation_rule_execute(%{
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

      # Verify execution event was created with nil fields
      executions = TestApp.Discord.AutoModerationRuleExecute.read!()
      assert length(executions) == 1

      created_execution = hd(executions)
      assert created_execution.guild_id == execute_data.guild_id
      assert created_execution.rule_id == execute_data.rule_id
      assert created_execution.user_id == execute_data.user_id
      assert created_execution.channel_id == nil
      assert created_execution.message_id == nil
      assert created_execution.matched_keyword == nil
    end
  end
end
