defmodule TestApp.Discord.GuildAuditLogEntry do
  @moduledoc """
  Test Discord Guild Audit Log Entry resource for validating audit log event transformations.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    discord_entity(:guild_audit_log_entry)
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Discord audit log entry ID"
    )

    attribute(:action_type, :integer,
      allow_nil?: false,
      public?: true,
      description: "Type of action that occurred"
    )

    attribute(:changes, {:array, :map},
      allow_nil?: true,
      public?: true,
      description: "Changes made to the target"
    )

    attribute(:options, :map,
      allow_nil?: true,
      public?: true,
      description: "Optional audit entry info"
    )

    attribute(:reason, :string,
      allow_nil?: true,
      public?: true,
      description: "Reason for the change"
    )

    attribute(:target_id, :string,
      allow_nil?: true,
      public?: true,
      description: "ID of the affected entity"
    )

    attribute(:user_id, :integer,
      allow_nil?: true,
      public?: true,
      description: "ID of the user who made the changes"
    )
  end

  identities do
    identity :discord_id, [:discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create guild audit log entry from Discord event data")
      primary?(true)

      argument(:data, :map,
        allow_nil?: false,
        description: "GuildAuditLogEntryCreateEvent TypedStruct"
      )

      change(AshDiscord.Changes.FromDiscord.GuildAuditLogEntry)

      upsert?(true)
      upsert_identity(:discord_id)

      upsert_fields([
        :action_type,
        :changes,
        :options,
        :reason,
        :target_id,
        :user_id
      ])
    end

    update :update do
      primary?(true)
      accept([:action_type, :changes, :options, :reason, :target_id, :user_id])
    end
  end
end
