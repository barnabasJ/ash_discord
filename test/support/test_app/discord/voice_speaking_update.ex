defmodule TestApp.Discord.VoiceSpeakingUpdate do
  @moduledoc """
  Test Discord VoiceSpeakingUpdate resource for validating voice speaking update event handling.

  This resource serves as a trace to verify that VOICE_SPEAKING_UPDATE events are properly
  received and processed by the handler. In production applications, users can
  attach their own side effects to this action.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ash_discord do
    events do
      on(:VOICE_SPEAKING_UPDATE, :from_discord)
    end
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:channel_discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Channel ID"
    )

    attribute(:guild_discord_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Guild ID"
    )

    attribute(:speaking, :boolean,
      allow_nil?: false,
      public?: true,
      description: "Whether the user is speaking"
    )

    attribute(:current_url, :string,
      allow_nil?: true,
      public?: true,
      description: "Current audio URL"
    )

    attribute(:timed_out, :boolean,
      allow_nil?: false,
      public?: true,
      description: "Whether the speaking update timed out"
    )

    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :channel, TestApp.Discord.Channel do
      source_attribute(:channel_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end

    belongs_to :guild, TestApp.Discord.Guild do
      source_attribute(:guild_discord_id)
      destination_attribute(:discord_id)
      attribute_writable?(true)
    end
  end

  identities do
    identity :discord_id, [:channel_discord_id, :guild_discord_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create voice speaking update event record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.VoiceSpeakingUpdateEvent,
        allow_nil?: false,
        description: "Discord voice speaking update event TypedStruct data"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :data) do
          %AshDiscord.Consumer.Payloads.VoiceSpeakingUpdateEvent{} = data ->
            changeset
            |> Ash.Changeset.force_change_attribute(:channel_discord_id, data.channel_id)
            |> Ash.Changeset.force_change_attribute(:guild_discord_id, data.guild_id)
            |> Ash.Changeset.force_change_attribute(:speaking, data.speaking)
            |> Ash.Changeset.force_change_attribute(:timed_out, data.timed_out)
            |> maybe_set_current_url(data.current_url)

          _ ->
            Ash.Changeset.add_error(
              changeset,
              "Invalid data argument: expected VoiceSpeakingUpdateEvent payload"
            )
        end
      end)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:speaking, :current_url, :timed_out])
    end
  end

  defp maybe_set_current_url(changeset, nil), do: changeset

  defp maybe_set_current_url(changeset, url) do
    Ash.Changeset.force_change_attribute(changeset, :current_url, url)
  end
end
