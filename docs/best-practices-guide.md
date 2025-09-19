# AshDiscord Best Practices Guide

This guide provides proven patterns and best practices for building robust, scalable Discord bots with AshDiscord, covering resource design, authorization, testing, and production deployment.

## Table of Contents

- [Resource Design Patterns](#resource-design-patterns)
- [Authorization Patterns](#authorization-patterns)
- [Background Job Patterns](#background-job-patterns)
- [Testing Strategies](#testing-strategies)
- [Performance Optimization](#performance-optimization)
- [Production Deployment](#production-deployment)
- [Error Handling Patterns](#error-handling-patterns)
- [Security Best Practices](#security-best-practices)

## Resource Design Patterns

### Pattern 1: Command-Specific Resources

**Use Case:** Simple commands that don't map to persistent entities.

```elixir
# ✅ Good: Dedicated resource for utility commands
defmodule MyBot.Utilities do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :ping, :string do
      run fn _input, _context ->
        {:ok, "🏓 Pong! Bot is responsive."}
      end
    end

    action :server_info, :map do
      run fn _input, context ->
        guild_id = context.guild_id
        
        case Nostrum.Api.get_guild(guild_id) do
          {:ok, guild} ->
            {:ok, %{
              name: guild.name,
              member_count: guild.member_count,
              created_at: Nostrum.Snowflake.creation_time(guild.id)
            }}
          {:error, _} ->
            {:error, "Unable to fetch server information"}
        end
      end
    end
  end
end
```

**Benefits:**
- Clear separation of concerns
- Easy to test individual utilities
- No database overhead for simple commands

### Pattern 2: Domain Entity Resources

**Use Case:** Commands that operate on business entities.

```elixir
# ✅ Good: Resource represents a real domain entity
defmodule MyBot.Event do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  postgres do
    table "events"
    repo MyBot.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:title, :description, :starts_at]
      
      argument :title, :string, allow_nil?: false
      argument :description, :string
      argument :starts_at, :datetime, allow_nil?: false
      
      change set_attribute(:creator_id, actor(:id))
      change set_attribute(:guild_id, actor(:guild_id))
    end

    read :upcoming do
      filter expr(starts_at > ^DateTime.utc_now())
      sort starts_at: :asc
    end

    read :by_creator do
      argument :creator_id, :string, allow_nil?: false
      filter expr(creator_id == ^arg(:creator_id))
    end
  end

  attributes do
    uuid_v7_primary_key :id
    
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :description, :string, public?: true
    attribute :starts_at, :datetime, allow_nil?: false, public?: true
    attribute :creator_id, :string, allow_nil?: false
    attribute :guild_id, :string, allow_nil?: false
    
    timestamps()
  end

  validations do
    validate present(:title), message: "Event title is required"
    validate string_length(:title, min: 3, max: 100)
    validate compare(:starts_at, greater_than: &DateTime.utc_now/0)
  end

  policies do
    # Only members of the guild can read events
    authorize_if actor_attribute_matches(:guild_id, :guild_id)
    
    # Only event creator or admins can modify
    authorize_if expr(creator_id == ^actor(:id))
    authorize_if actor_attribute_matches(:role, :admin)
  end
end
```

**Benefits:**
- Full CRUD operations available
- Built-in validation and authorization
- Leverages Ash's query capabilities
- Clear ownership and permissions

### Pattern 3: Discord Entity Resources

**Use Case:** Resources that mirror Discord entities for local operations.

```elixir
# ✅ Good: Local representation of Discord guild for extended functionality
defmodule MyBot.Guild do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  postgres do
    table "guilds"
    repo MyBot.Repo
  end

  actions do
    defaults [:read, :update]

    create :from_discord do
      argument :discord_id, :string, allow_nil?: false
      
      upsert? true
      upsert_identity :discord_id
      upsert_fields [:name, :icon, :member_count, :features]
      
      change fn changeset, context ->
        discord_id = Ash.Changeset.get_argument(changeset, :discord_id)
        
        case Nostrum.Api.get_guild(String.to_integer(discord_id)) do
          {:ok, guild} ->
            changeset
            |> Ash.Changeset.change_attribute(:discord_id, to_string(guild.id))
            |> Ash.Changeset.change_attribute(:name, guild.name)
            |> Ash.Changeset.change_attribute(:icon, guild.icon)
            |> Ash.Changeset.change_attribute(:member_count, guild.member_count)
            |> Ash.Changeset.change_attribute(:features, guild.features)
            
          {:error, _} ->
            Ash.Changeset.add_error(changeset, "Failed to fetch guild from Discord")
        end
      end
    end

    read :active_guilds do
      filter expr(is_active == true)
    end

    update :update_settings do
      accept [:welcome_channel_id, :moderation_channel_id, :auto_role_id]
      require_atomic? false
    end
  end

  attributes do
    uuid_v7_primary_key :id
    
    attribute :discord_id, :string, allow_nil?: false, public?: true
    attribute :name, :string, allow_nil?: false
    attribute :icon, :string
    attribute :member_count, :integer, default: 0
    attribute :features, {:array, :string}, default: []
    
    # Bot-specific settings
    attribute :welcome_channel_id, :string
    attribute :moderation_channel_id, :string  
    attribute :auto_role_id, :string
    attribute :is_active, :boolean, default: true
    
    timestamps()
  end

  identities do
    identity :discord_id, [:discord_id]
  end

  policies do
    # Only bot operations can create/update guild records
    authorize_if actor_attribute_equals(:role, :bot)
    
    # Guild members can read guild info
    authorize_if expr(
      exists(members, user_id == ^actor(:id))
    )
  end

  relationships do
    has_many :members, MyBot.GuildMember do
      destination_attribute :guild_id
    end

    has_many :events, MyBot.Event do
      destination_attribute :guild_id
    end
  end
end
```

**Benefits:**
- Sync Discord state with local database
- Extended functionality beyond Discord API
- Consistent data access patterns
- Bot-specific configuration storage

### Pattern 4: Action Organization

**✅ Good: Organize actions by purpose**

```elixir
defmodule MyBot.ModerationActions do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    # User-facing moderation commands
    action :warn_user, :map do
      argument :user_id, :string, allow_nil?: false
      argument :reason, :string, default: "No reason provided"
      
      run &warn_user_impl/2
    end

    action :timeout_user, :map do
      argument :user_id, :string, allow_nil?: false
      argument :duration_minutes, :integer, default: 10
      argument :reason, :string, default: "Timeout"
      
      run &timeout_user_impl/2
    end

    # Administrative actions
    action :ban_user, :map do
      argument :user_id, :string, allow_nil?: false
      argument :reason, :string, default: "Banned by moderator"
      argument :delete_message_days, :integer, default: 0
      
      run &ban_user_impl/2
    end

    # Utility actions (not exposed as commands)
    action :log_moderation_action, :struct do
      argument :action_type, :string, allow_nil?: false
      argument :target_user_id, :string, allow_nil?: false
      argument :moderator_id, :string, allow_nil?: false
      argument :reason, :string
      
      run &log_moderation_impl/2
    end
  end

  policies do
    # Different permissions for different action types
    authorize_if action_type(:warn_user) and actor_has_permission(:timeout_members)
    authorize_if action_type(:timeout_user) and actor_has_permission(:timeout_members)  
    authorize_if action_type(:ban_user) and actor_has_permission(:ban_members)
    authorize_if action_type(:log_moderation_action) and actor_attribute_equals(:role, :bot)
  end

  # Implementation functions kept private
  defp warn_user_impl(%{arguments: %{user_id: user_id, reason: reason}}, context) do
    # Implementation details...
  end

  defp timeout_user_impl(input, context) do
    # Implementation details...
  end

  defp ban_user_impl(input, context) do
    # Implementation details...  
  end

  defp log_moderation_impl(input, context) do
    # Implementation details...
  end
end
```

## Authorization Patterns

### Pattern 1: Role-Based Authorization

```elixir
defmodule MyBot.AdminCommands do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :purge_messages, :map do
      argument :count, :integer, allow_nil?: false
      argument :channel_id, :string, allow_nil?: false
      
      run &purge_messages_impl/2
    end

    action :change_settings, :map do
      argument :setting_name, :string, allow_nil?: false
      argument :setting_value, :string, allow_nil?: false
      
      run &change_settings_impl/2
    end
  end

  policies do
    # Multiple ways to check for admin permissions
    authorize_if actor_attribute_equals(:role, :admin)
    authorize_if actor_attribute_equals(:role, :owner)
    authorize_if actor_has_permission(:administrator)
    
    # Specific guild-based permissions
    authorize_if expr(
      exists(guild_members, 
        user_id == ^actor(:id) and has_permission == true and guild_id == ^context(:guild_id)
      )
    )
  end

  # Custom policy functions
  defp actor_has_permission(permission) do
    fn actor, _context ->
      case actor do
        %{permissions: perms} when is_list(perms) ->
          permission in perms
        %{discord_permissions: discord_perms} ->
          has_discord_permission?(discord_perms, permission)
        _ ->
          false
      end
    end
  end
end
```

### Pattern 2: Resource-Level Authorization

```elixir
defmodule MyBot.UserPost do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  actions do
    create :create do
      accept [:title, :content]
      change set_attribute(:author_id, actor(:id))
    end

    update :edit do
      accept [:title, :content]
    end

    destroy :delete
  end

  policies do
    # Default: deny all access
    default_access_type :deny

    # Anyone can read posts
    authorize_if action_type(:read)
    
    # Users can create their own posts  
    authorize_if action_type(:create)

    # Users can only edit/delete their own posts
    authorize_if action_type([:update, :destroy]) and expr(author_id == ^actor(:id))

    # Moderators can edit/delete any post
    authorize_if action_type([:update, :destroy]) and actor_attribute_equals(:role, :moderator)

    # Special case: system can do anything
    authorize_if actor_attribute_equals(:role, :system)
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :content, :string, allow_nil?: false, public?: true  
    attribute :author_id, :string, allow_nil?: false
    timestamps()
  end
end
```

### Pattern 3: Guild Context Authorization

```elixir
defmodule MyBot.GuildSettings do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  actions do
    read :get_settings do
      get? true
    end

    update :update_settings do
      accept [:welcome_message, :auto_role_id, :moderation_channel_id]
    end
  end

  policies do
    # Must be a member of the guild to access settings
    authorize_if expr(
      exists(guild_members, user_id == ^actor(:id) and guild_id == ^resource(:guild_id))
    )

    # Must have manage server permission to modify
    authorize_if action_type(:update) and actor_has_guild_permission(:manage_guild)
  end

  # Custom policy check for guild permissions
  defp actor_has_guild_permission(permission) do
    fn actor, context ->
      guild_id = context.resource.guild_id
      user_id = actor.id
      
      case MyBot.PermissionChecker.has_permission?(user_id, guild_id, permission) do
        {:ok, true} -> true
        _ -> false
      end
    end
  end
end
```

## Background Job Patterns

### Pattern 1: Simple Background Actions

```elixir
defmodule MyBot.BackgroundTasks do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :generate_report, :map do
      argument :report_type, :string, allow_nil?: false
      argument :guild_id, :string, allow_nil?: false
      
      run fn %{arguments: args}, context ->
        # Queue background job
        %{
          report_type: args.report_type,
          guild_id: args.guild_id,
          requester_id: context.actor.id,
          interaction_token: context.interaction_token
        }
        |> MyBot.Workers.ReportWorker.new(schedule_in: 5)
        |> Oban.insert()
        
        {:ok, %{
          status: "queued",
          message: "Report generation started. You'll receive the results shortly."
        }}
      end
    end
  end
end

# Dedicated worker
defmodule MyBot.Workers.ReportWorker do
  use Oban.Worker, queue: :reports, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "report_type" => report_type,
      "guild_id" => guild_id,
      "requester_id" => requester_id,
      "interaction_token" => token
    } = args

    case generate_report(report_type, guild_id) do
      {:ok, report_data} ->
        send_report_response(token, report_data)
        :ok
      {:error, reason} ->
        send_error_response(token, "Failed to generate report: #{reason}")
        {:error, reason}
    end
  end

  defp generate_report("activity", guild_id) do
    # Generate activity report
    {:ok, %{type: "activity", data: []}}
  end

  defp generate_report("members", guild_id) do
    # Generate member report  
    {:ok, %{type: "members", data: []}}
  end

  defp send_report_response(token, report_data) do
    # Send followup message with report
    Nostrum.Api.create_followup_message(
      Application.get_env(:my_bot, :application_id),
      token,
      %{
        content: "Report generated successfully!",
        files: [create_report_file(report_data)]
      }
    )
  end
end
```

### Pattern 2: Multi-Step Job Workflows

```elixir
defmodule MyBot.ComplexWorkflow do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  postgres do
    table "workflow_jobs"
    repo MyBot.Repo
  end

  actions do
    create :start_workflow do
      argument :workflow_type, :string, allow_nil?: false
      argument :parameters, :map, default: %{}
      
      change set_attribute(:status, :pending)
      change set_attribute(:created_by, actor(:id))
      change set_attribute(:steps_completed, 0)
      change set_attribute(:total_steps, 3)
      
      change after_action(&enqueue_first_step/3)
    end

    update :advance_step do
      argument :step_result, :map
      
      change increment(:steps_completed)
      change append_to_attribute(:step_results, arg(:step_result))
      
      change conditional do
        condition expr(steps_completed >= total_steps)
        change set_attribute(:status, :completed)
        change after_action(&send_completion_notification/3)
      end
      
      change conditional do
        condition expr(steps_completed < total_steps)
        change after_action(&enqueue_next_step/3)
      end
    end

    update :fail_workflow do
      argument :error_message, :string
      
      change set_attribute(:status, :failed)
      change set_attribute(:error_message, arg(:error_message))
      change after_action(&send_failure_notification/3)
    end
  end

  attributes do
    uuid_v7_primary_key :id
    
    attribute :workflow_type, :string, allow_nil?: false
    attribute :parameters, :map, default: %{}
    attribute :status, :atom, default: :pending
    attribute :steps_completed, :integer, default: 0
    attribute :total_steps, :integer, default: 1
    attribute :step_results, {:array, :map}, default: []
    attribute :created_by, :string, allow_nil?: false
    attribute :error_message, :string
    
    timestamps()
  end

  # Enqueue workflow steps
  defp enqueue_first_step(changeset, workflow, _context) do
    %{workflow_id: workflow.id, step: 1}
    |> MyBot.Workers.WorkflowStepWorker.new()
    |> Oban.insert()
    
    {:ok, workflow}
  end

  defp enqueue_next_step(changeset, workflow, _context) do
    next_step = workflow.steps_completed + 1
    
    if next_step <= workflow.total_steps do
      %{workflow_id: workflow.id, step: next_step}
      |> MyBot.Workers.WorkflowStepWorker.new()
      |> Oban.insert()
    end
    
    {:ok, workflow}
  end
end

# Step worker
defmodule MyBot.Workers.WorkflowStepWorker do
  use Oban.Worker, queue: :workflows

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"workflow_id" => workflow_id, "step" => step}}) do
    case MyBot.ComplexWorkflow.get!(workflow_id) do
      workflow when workflow.status == :pending ->
        case execute_step(workflow, step) do
          {:ok, result} ->
            MyBot.ComplexWorkflow.advance_step!(workflow, %{step_result: result})
            :ok
          {:error, reason} ->
            MyBot.ComplexWorkflow.fail_workflow!(workflow, %{error_message: reason})
            {:error, reason}
        end
      _ ->
        # Workflow already completed or failed
        :ok
    end
  end

  defp execute_step(workflow, 1) do
    # Step 1: Initialize data
    {:ok, %{step: 1, status: "initialized", data: %{}}}
  end

  defp execute_step(workflow, 2) do
    # Step 2: Process data
    {:ok, %{step: 2, status: "processed", data: %{}}}
  end

  defp execute_step(workflow, 3) do
    # Step 3: Finalize
    {:ok, %{step: 3, status: "finalized", data: %{}}}
  end
end
```

## Testing Strategies

### Pattern 1: Action Testing

```elixir
defmodule MyBot.EventTest do
  use ExUnit.Case
  use MyBot.DataCase

  describe "Event.create action" do
    test "creates event with valid attributes" do
      actor = build_user_actor()
      
      assert {:ok, event} = MyBot.Event.create(
        %{title: "Test Event", starts_at: future_datetime()},
        actor: actor
      )
      
      assert event.title == "Test Event"
      assert event.creator_id == actor.id
      assert event.guild_id == actor.guild_id
    end

    test "validates required fields" do
      actor = build_user_actor()
      
      assert {:error, %Ash.Error.Invalid{} = error} = MyBot.Event.create(
        %{title: ""},  # Empty title should fail
        actor: actor
      )
      
      assert "Event title is required" in error_messages(error)
    end

    test "validates future start time" do
      actor = build_user_actor()
      past_time = DateTime.add(DateTime.utc_now(), -3600, :second)
      
      assert {:error, %Ash.Error.Invalid{} = error} = MyBot.Event.create(
        %{title: "Past Event", starts_at: past_time},
        actor: actor
      )
      
      assert "must be in the future" in error_messages(error)
    end
  end

  # Helper functions
  defp build_user_actor do
    %{id: "123456789", guild_id: "987654321", role: :user}
  end

  defp future_datetime do
    DateTime.add(DateTime.utc_now(), 3600, :second)
  end

  defp error_messages(error) do
    error.errors
    |> Enum.map(& &1.message)
    |> Enum.join(", ")
  end
end
```

### Pattern 2: Command Integration Testing

```elixir
defmodule MyBot.CommandIntegrationTest do
  use ExUnit.Case
  use Mimic

  import MyBot.TestHelpers

  setup do
    # Setup test guild and user
    guild_id = "123456789"
    user_id = "987654321"
    
    user_actor = %{
      id: user_id, 
      guild_id: guild_id,
      discord_permissions: [:manage_messages]
    }
    
    %{guild_id: guild_id, user_id: user_id, actor: user_actor}
  end

  describe "/create_event command" do
    test "creates event successfully", %{actor: actor} do
      # Mock the Discord interaction
      interaction = build_interaction(:create_event, %{
        title: "Team Meeting",
        starts_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }, user: actor)

      command = MyBot.TestHelpers.find_command(:create_event)
      
      assert {:ok, response} = AshDiscord.InteractionRouter.route_interaction(
        interaction,
        command,
        user_creator: fn _discord_user -> actor end
      )
      
      assert response.content =~ "Event created successfully"
      
      # Verify event was actually created
      events = MyBot.Event.by_creator!(actor.id, actor: actor)
      assert length(events) == 1
      assert hd(events).title == "Team Meeting"
    end

    test "handles validation errors gracefully", %{actor: actor} do
      interaction = build_interaction(:create_event, %{
        title: "",  # Invalid empty title
        starts_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }, user: actor)

      command = MyBot.TestHelpers.find_command(:create_event)
      
      assert {:ok, response} = AshDiscord.InteractionRouter.route_interaction(
        interaction,
        command,
        user_creator: fn _discord_user -> actor end
      )
      
      assert response.content =~ "Event title is required"
      assert response.flags == 64  # EPHEMERAL flag
    end
  end
end

# Test helpers module
defmodule MyBot.TestHelpers do
  def build_interaction(command_name, options, opts \\ []) do
    user = Keyword.get(opts, :user, %{id: "123456789"})
    guild_id = Keyword.get(opts, :guild_id, "987654321")
    
    %{
      id: "interaction_#{:rand.uniform(10000)}",
      token: "test_token",
      type: 2,  # APPLICATION_COMMAND
      data: %{
        id: "command_#{:rand.uniform(10000)}",
        name: to_string(command_name),
        type: 1,  # CHAT_INPUT
        options: build_options(options)
      },
      guild_id: guild_id,
      channel_id: "channel_123",
      user: user,
      member: %{user: user}
    }
  end

  def build_options(options) when is_map(options) do
    Enum.map(options, fn {key, value} ->
      %{
        name: to_string(key),
        value: format_option_value(value),
        type: option_type_for_value(value)
      }
    end)
  end

  defp format_option_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_option_value(value), do: value

  defp option_type_for_value(value) when is_binary(value), do: 3  # STRING
  defp option_type_for_value(value) when is_integer(value), do: 4  # INTEGER
  defp option_type_for_value(value) when is_boolean(value), do: 5  # BOOLEAN
  defp option_type_for_value(%DateTime{}), do: 3  # STRING (ISO8601)

  def find_command(command_name) do
    MyBot.Discord
    |> AshDiscord.Info.discord_commands()
    |> Enum.find(fn cmd -> cmd.name == command_name end)
  end
end
```

### Pattern 3: Consumer Testing

```elixir
defmodule MyBot.ConsumerTest do
  use ExUnit.Case
  use Mimic

  describe "message handling" do
    test "responds to ping command" do
      message = %{
        id: "message_123",
        content: "!ping",
        author: %{id: "user_123", bot: false},
        channel_id: "channel_123",
        guild_id: "guild_123"
      }

      # Mock Discord API response
      expect(Nostrum.Api, :create_message, fn channel_id, content ->
        assert channel_id == "channel_123"
        assert content == "🏓 Pong!"
        {:ok, %{id: "response_123"}}
      end)

      # Test the message handler
      assert :ok = MyBot.DiscordConsumer.handle_message_create(message)
    end

    test "ignores bot messages" do
      message = %{
        id: "message_123",
        content: "!ping",
        author: %{id: "bot_123", bot: true},
        channel_id: "channel_123",
        guild_id: "guild_123"
      }

      # Should not call Discord API
      reject(&Nostrum.Api.create_message/2)

      assert :ok = MyBot.DiscordConsumer.handle_message_create(message)
    end
  end

  describe "guild event handling" do
    test "handles guild creation" do
      guild = %{
        id: 123456789,
        name: "Test Guild",
        member_count: 100,
        features: ["COMMUNITY"]
      }

      # Mock successful guild creation in database
      expect(MyBot.Guild, :from_discord, fn %{discord_id: discord_id} ->
        assert discord_id == "123456789"
        {:ok, %MyBot.Guild{discord_id: discord_id, name: "Test Guild"}}
      end)

      assert :ok = MyBot.DiscordConsumer.handle_guild_create(guild)
    end
  end
end
```

## Performance Optimization

### Pattern 1: Callback Configuration

```elixir
# ✅ Good: Environment-specific optimization
defmodule MyBot.ProductionConsumer do
  use AshDiscord.Consumer,
    domains: [MyBot.Discord],
    callback_config: :production,  # Optimized for production
    disable_callbacks: [
      :typing_events,      # Very frequent, usually not needed
      :voice_events,       # Only needed for music bots
      :invite_events       # Usually not business-critical
    ],
    debug_logging: false,  # Reduce log overhead
    auto_create_users: true

  # Override only what you need
  def handle_message_create(message) do
    # Only process if bot is mentioned or it's a DM
    if should_process_message?(message) do
      MyBot.MessageHandler.process(message)
    end
    :ok
  end

  defp should_process_message?(message) do
    message.guild_id == nil or bot_mentioned?(message)
  end
end

# ✅ Good: Development configuration
defmodule MyBot.DevelopmentConsumer do
  use AshDiscord.Consumer,
    domains: [MyBot.Discord],
    callback_config: :development,  # Full logging
    debug_logging: true,
    store_bot_messages: true        # Useful for development

  # Enhanced logging for development
  def handle_ready(data) do
    Logger.info("🚀 Bot ready in development mode!")
    Logger.debug("Connected guilds: #{length(data.guilds)}")
    :ok
  end
end
```

### Pattern 2: Efficient Data Loading

```elixir
defmodule MyBot.OptimizedQueries do
  use Ash.Resource, 
    otp_app: :my_bot, 
    data_layer: AshPostgres.DataLayer

  actions do
    # ✅ Good: Load related data efficiently
    read :events_with_attendees do
      prepare build(load: [:creator, attendees: [:user]])
      
      filter expr(starts_at > ^DateTime.utc_now())
      sort starts_at: :asc
    end

    # ✅ Good: Pagination for large datasets
    read :recent_activity do
      pagination offset?: true, default_limit: 25, max_page_size: 100
      
      prepare build(load: [:user])
      sort inserted_at: :desc
    end

    # ✅ Good: Aggregate queries for statistics  
    read :guild_stats do
      prepare build(
        aggregate: [
          :total_events,
          :active_users,
          :messages_today
        ]
      )
    end
  end

  # Efficient aggregates
  aggregates do
    count :total_events, :events
    
    count :active_users, :guild_members do
      filter expr(last_seen > ^DateTime.add(DateTime.utc_now(), -7, :day))
    end

    count :messages_today, :messages do
      filter expr(inserted_at > ^DateTime.beginning_of_day(DateTime.utc_now()))
    end
  end
end
```

### Pattern 3: Caching Strategies

```elixir
defmodule MyBot.CachedOperations do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :get_guild_info, :map do
      argument :guild_id, :string, allow_nil?: false
      
      run fn %{arguments: %{guild_id: guild_id}}, _context ->
        # Cache expensive Discord API calls
        case get_cached_guild_info(guild_id) do
          {:ok, cached_info} ->
            {:ok, cached_info}
          :not_found ->
            case fetch_and_cache_guild_info(guild_id) do
              {:ok, info} -> {:ok, info}
              {:error, _} -> {:error, "Failed to fetch guild information"}
            end
        end
      end
    end
  end

  defp get_cached_guild_info(guild_id) do
    case :ets.lookup(:guild_cache, guild_id) do
      [{^guild_id, info, expires_at}] ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:ok, info}
        else
          :ets.delete(:guild_cache, guild_id)
          :not_found
        end
      [] ->
        :not_found
    end
  end

  defp fetch_and_cache_guild_info(guild_id) do
    case Nostrum.Api.get_guild(String.to_integer(guild_id)) do
      {:ok, guild} ->
        info = %{
          name: guild.name,
          member_count: guild.member_count,
          features: guild.features
        }
        
        expires_at = DateTime.add(DateTime.utc_now(), 300, :second)  # 5 min cache
        :ets.insert(:guild_cache, {guild_id, info, expires_at})
        
        {:ok, info}
      {:error, reason} ->
        {:error, reason}
    end
  end
end

# Initialize cache in your Application module
defmodule MyBot.Application do
  def start(_type, _args) do
    # Create ETS cache table
    :ets.new(:guild_cache, [:set, :public, :named_table])
    
    children = [
      # ... other children
      {MyBot.DiscordConsumer, []}
    ]
    
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

## Production Deployment

### Pattern 1: Configuration Management

```elixir
# config/runtime.exs
import Config

# Discord Configuration
config :nostrum,
  token: System.get_env("DISCORD_BOT_TOKEN") || raise("DISCORD_BOT_TOKEN not set"),
  gateway_intents: [
    :guilds,
    :guild_messages,
    :guild_message_reactions,
    :direct_messages
  ]

# Application Configuration
config :my_bot,
  environment: System.get_env("BOT_ENVIRONMENT", "production"),
  log_level: System.get_env("LOG_LEVEL", "info") |> String.to_existing_atom(),
  application_id: System.get_env("DISCORD_APPLICATION_ID") || raise("DISCORD_APPLICATION_ID not set")

# Database Configuration
database_url = System.get_env("DATABASE_URL") || raise("DATABASE_URL not set")

config :my_bot, MyBot.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  ssl: true,
  ssl_opts: [
    verify: :verify_none
  ]

# Oban Configuration (Background Jobs)
config :my_bot, Oban,
  repo: MyBot.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Clean up old data every day at 2 AM
       {"0 2 * * *", MyBot.Workers.CleanupWorker}
     ]}
  ],
  queues: [
    default: 10,
    discord_responses: 5,
    reports: 2,
    cleanup: 1
  ]
```

### Pattern 2: Health Checks and Monitoring

```elixir
defmodule MyBot.HealthCheck do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :health_status, :map do
      run fn _input, _context ->
        checks = [
          {:database, check_database()},
          {:discord, check_discord_connection()},
          {:oban, check_oban_status()},
          {:memory, check_memory_usage()},
          {:disk, check_disk_space()}
        ]

        all_healthy = Enum.all?(checks, fn {_name, status} -> status == :ok end)
        
        {:ok, %{
          status: if(all_healthy, do: :healthy, else: :unhealthy),
          checks: Map.new(checks),
          timestamp: DateTime.utc_now(),
          uptime: get_uptime()
        }}
      end
    end
  end

  defp check_database do
    try do
      MyBot.Repo.query!("SELECT 1")
      :ok
    rescue
      _ -> :error
    end
  end

  defp check_discord_connection do
    case Nostrum.Cache.Me.get() do
      %Nostrum.Struct.User{} -> :ok
      _ -> :error
    end
  end

  defp check_oban_status do
    case Oban.check_queue(MyBot.Oban, queue: :default) do
      :ok -> :ok
      _ -> :error
    end
  end

  defp check_memory_usage do
    memory = :erlang.memory(:total)
    max_memory = 500 * 1024 * 1024  # 500MB limit
    
    if memory < max_memory, do: :ok, else: :warning
  end

  defp check_disk_space do
    # Implementation depends on your deployment
    :ok
  end

  defp get_uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_ms / 1000
  end
end
```

### Pattern 3: Graceful Shutdown

```elixir
defmodule MyBot.Application do
  use Application

  def start(_type, _args) do
    # Register shutdown handler
    :erlang.process_flag(:trap_exit, true)
    
    children = [
      MyBot.Repo,
      {Oban, oban_config()},
      MyBot.DiscordConsumer
    ]

    opts = [strategy: :one_for_one, name: MyBot.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("MyBot started successfully")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start MyBot: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def stop(_state) do
    Logger.info("MyBot is shutting down gracefully...")
    
    # Stop accepting new Discord events
    :ok = Nostrum.Consumer.stop(MyBot.DiscordConsumer)
    
    # Wait for current jobs to finish
    :ok = Oban.drain_queue(MyBot.Oban, queue: :default, timeout: 30_000)
    
    # Close database connections
    :ok = MyBot.Repo.stop()
    
    Logger.info("MyBot shutdown complete")
    :ok
  end

  defp oban_config do
    Application.get_env(:my_bot, Oban)
  end
end
```

## Error Handling Patterns

### Pattern 1: Structured Error Responses

```elixir
defmodule MyBot.ErrorHandling do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :risky_operation, :map do
      argument :operation_type, :string, allow_nil?: false
      
      run fn %{arguments: %{operation_type: type}}, context ->
        case perform_operation(type) do
          {:ok, result} -> 
            {:ok, result}
          {:error, :not_found} -> 
            {:error, "The requested resource was not found"}
          {:error, :permission_denied} -> 
            {:error, "You don't have permission to perform this action"}
          {:error, :rate_limited} -> 
            {:error, "Rate limit exceeded. Please try again later"}
          {:error, :discord_api_error, details} -> 
            handle_discord_error(details, context)
          {:error, reason} when is_binary(reason) -> 
            {:error, reason}
          {:error, reason} -> 
            Logger.error("Unexpected error in risky_operation: #{inspect(reason)}")
            {:error, "An unexpected error occurred"}
        end
      end
    end
  end

  defp handle_discord_error(%{status: 429}, _context) do
    {:error, "Discord API rate limit hit. Please wait a moment and try again"}
  end

  defp handle_discord_error(%{status: 403}, _context) do
    {:error, "Bot lacks necessary permissions for this action"}
  end

  defp handle_discord_error(%{status: 404}, _context) do
    {:error, "Discord resource not found (may have been deleted)"}
  end

  defp handle_discord_error(details, _context) do
    Logger.error("Discord API error: #{inspect(details)}")
    {:error, "Discord service temporarily unavailable"}
  end
end
```

### Pattern 2: Error Recovery

```elixir
defmodule MyBot.RetryableOperations do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :send_important_message, :map do
      argument :channel_id, :string, allow_nil?: false
      argument :content, :string, allow_nil?: false
      argument :max_retries, :integer, default: 3
      
      run &send_with_retry/2
    end
  end

  defp send_with_retry(%{arguments: args}, _context) do
    send_message_with_retry(
      args.channel_id, 
      args.content, 
      args.max_retries
    )
  end

  defp send_message_with_retry(channel_id, content, retries_left) when retries_left > 0 do
    case Nostrum.Api.create_message(channel_id, content) do
      {:ok, message} -> 
        {:ok, %{message_id: message.id, status: "sent"}}
        
      {:error, %{status_code: 429, response: %{"retry_after" => retry_after}}} ->
        Logger.warn("Rate limited, retrying after #{retry_after}ms")
        Process.sleep(retry_after)
        send_message_with_retry(channel_id, content, retries_left - 1)
        
      {:error, %{status_code: status}} when status in [500, 502, 503, 504] ->
        Logger.warn("Discord server error (#{status}), retrying...")
        Process.sleep(2000)  # Wait 2 seconds
        send_message_with_retry(channel_id, content, retries_left - 1)
        
      {:error, reason} ->
        {:error, "Failed to send message: #{inspect(reason)}"}
    end
  end

  defp send_message_with_retry(_channel_id, _content, 0) do
    {:error, "Failed to send message after maximum retries"}
  end
end
```

## Security Best Practices

### Pattern 1: Input Validation and Sanitization

```elixir
defmodule MyBot.SecureOperations do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :create_announcement, :map do
      argument :title, :string, allow_nil?: false
      argument :content, :string, allow_nil?: false
      argument :mention_role, :string
      
      validate string_length(:title, max: 100)
      validate string_length(:content, max: 2000)
      
      run &create_announcement_impl/2
    end
  end

  defp create_announcement_impl(%{arguments: args}, context) do
    # Sanitize inputs
    safe_title = sanitize_discord_content(args.title)
    safe_content = sanitize_discord_content(args.content)
    
    # Validate mention role if provided
    safe_mention = case args.mention_role do
      nil -> nil
      role_id -> validate_role_access(role_id, context.actor)
    end

    case safe_mention do
      {:error, reason} -> {:error, reason}
      _ -> 
        content_with_mention = build_announcement_content(
          safe_title, 
          safe_content, 
          safe_mention
        )
        
        {:ok, %{
          title: safe_title,
          content: content_with_mention,
          created_by: context.actor.id
        }}
    end
  end

  defp sanitize_discord_content(content) do
    content
    |> String.replace(~r/@everyone/, "@\u200beveryone")  # Prevent @everyone
    |> String.replace(~r/@here/, "@\u200bhere")          # Prevent @here
    |> String.slice(0, 2000)                             # Enforce Discord limits
  end

  defp validate_role_access(role_id, actor) do
    # Check if actor can mention this role
    case MyBot.PermissionChecker.can_mention_role?(actor.id, role_id) do
      true -> {:ok, "<@&#{role_id}>"}
      false -> {:error, "You cannot mention this role"}
    end
  end

  defp build_announcement_content(title, content, mention) do
    parts = [
      mention,
      "**#{title}**",
      content
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
    
    String.trim(parts)
  end
end
```

### Pattern 2: Permission Validation

```elixir
defmodule MyBot.SecureModeration do
  use Ash.Resource, otp_app: :my_bot, data_layer: :embedded

  actions do
    action :ban_user, :map do
      argument :user_id, :string, allow_nil?: false
      argument :reason, :string, default: "No reason provided"
      argument :delete_message_days, :integer, default: 0
      
      run &ban_user_impl/2
    end
  end

  policies do
    # Multiple layers of permission checking
    authorize_if actor_has_discord_permission(:ban_members)
    authorize_if not_self_action()
    authorize_if target_user_below_actor()
  end

  defp ban_user_impl(%{arguments: args}, context) do
    target_user_id = args.user_id
    actor = context.actor
    
    # Additional runtime security checks
    with :ok <- validate_not_self_ban(target_user_id, actor.id),
         :ok <- validate_hierarchy(target_user_id, actor, context.guild_id),
         :ok <- validate_ban_permissions(actor, context.guild_id),
         {:ok, _} <- execute_ban(target_user_id, args, context.guild_id) do
      
      # Log the moderation action
      log_moderation_action(:ban, target_user_id, actor.id, args.reason)
      
      {:ok, %{
        action: "ban",
        target_user_id: target_user_id,
        reason: args.reason,
        moderator_id: actor.id
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Security validation functions
  defp validate_not_self_ban(user_id, user_id), do: {:error, "Cannot ban yourself"}
  defp validate_not_self_ban(_, _), do: :ok

  defp validate_hierarchy(target_id, actor, guild_id) do
    case MyBot.HierarchyChecker.compare_roles(actor.id, target_id, guild_id) do
      :higher -> :ok
      :equal -> {:error, "Cannot ban users with equal or higher role"}
      :lower -> {:error, "Cannot ban users with higher role"}
    end
  end

  defp validate_ban_permissions(actor, guild_id) do
    case MyBot.PermissionChecker.has_permission?(actor.id, guild_id, :ban_members) do
      true -> :ok
      false -> {:error, "Missing ban members permission"}
    end
  end

  defp execute_ban(user_id, args, guild_id) do
    Nostrum.Api.create_guild_ban(
      String.to_integer(guild_id),
      String.to_integer(user_id),
      %{
        reason: args.reason,
        delete_message_days: args.delete_message_days
      }
    )
  end

  defp log_moderation_action(action, target_id, moderator_id, reason) do
    MyBot.ModerationLog.create!(%{
      action: action,
      target_user_id: target_id,
      moderator_id: moderator_id,
      reason: reason,
      timestamp: DateTime.utc_now()
    })
  end

  # Custom policy functions
  defp not_self_action do
    fn actor, %{arguments: %{user_id: target_id}} ->
      actor.id != target_id
    end
  end

  defp target_user_below_actor do
    fn actor, %{arguments: %{user_id: target_id}, guild_id: guild_id} ->
      case MyBot.HierarchyChecker.compare_roles(actor.id, target_id, guild_id) do
        :higher -> true
        _ -> false
      end
    end
  end
end
```

This comprehensive best practices guide provides production-ready patterns for building robust, scalable Discord bots with AshDiscord. Each pattern includes real-world examples and addresses common challenges you'll encounter when scaling your bot beyond basic functionality.