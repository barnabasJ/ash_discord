defmodule TestApp.Discord.VoiceReady do
  @moduledoc """
  Test Discord VoiceReady resource for validating voice ready event handling.

  This resource serves as a trace to verify that VOICE_READY events are properly
  received and processed by the handler. In production applications, users can
  attach their own side effects to this action.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:channel_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Channel ID that voice is ready in"
    )

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Guild ID that voice is ready in"
    )

    create_timestamp(:inserted_at)
  end

  identities do
    identity :discord_id, [:channel_id, :guild_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create voice ready event record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.VoiceReadyEvent,
        allow_nil?: false,
        description: "Discord voice ready event TypedStruct data"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :data) do
          %AshDiscord.Consumer.Payloads.VoiceReadyEvent{} = data ->
            changeset
            |> Ash.Changeset.force_change_attribute(:channel_id, data.channel_id)
            |> Ash.Changeset.force_change_attribute(:guild_id, data.guild_id)

          _ ->
            Ash.Changeset.add_error(
              changeset,
              "Invalid data argument: expected VoiceReadyEvent payload"
            )
        end
      end)

      upsert?(true)
      upsert_identity(:discord_id)
    end
  end
end
