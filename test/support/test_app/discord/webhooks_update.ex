defmodule TestApp.Discord.WebhooksUpdate do
  @moduledoc """
  Test Discord WebhooksUpdate resource for validating webhooks update event handling.

  This resource serves as a trace to verify that WEBHOOKS_UPDATE events are properly
  received and processed by the handler. The WEBHOOKS_UPDATE event only contains
  guild_id and channel_id - it does NOT specify which webhook changed or what action
  occurred. It's an informational "ping" that something changed.

  In production applications, users can attach their own side effects to this action,
  such as querying the API to fetch current webhooks and updating their cache.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Guild ID where webhooks changed"
    )

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Channel ID where webhooks changed"
    )

    create_timestamp(:inserted_at)
  end

  identities do
    identity :discord_id, [:guild_id, :channel_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create webhooks update event record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.WebhooksUpdateEvent,
        allow_nil?: false,
        description: "Discord webhooks update event TypedStruct data"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :data) do
          %AshDiscord.Consumer.Payloads.WebhooksUpdateEvent{} = data ->
            changeset
            |> Ash.Changeset.force_change_attribute(:guild_id, data.guild_id)
            |> Ash.Changeset.force_change_attribute(:channel_id, data.channel_id)

          _ ->
            Ash.Changeset.add_error(
              changeset,
              "Invalid data argument: expected WebhooksUpdateEvent payload"
            )
        end
      end)

      upsert?(true)
      upsert_identity(:discord_id)
    end
  end
end
