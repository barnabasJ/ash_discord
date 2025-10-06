defmodule TestApp.Discord.VoiceServerUpdate do
  @moduledoc """
  Test Discord VoiceServerUpdate resource for validating voice server update event handling.

  This resource serves as a trace to verify that VOICE_SERVER_UPDATE events are properly
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

    attribute(:token, :string,
      allow_nil?: false,
      public?: true,
      description: "Voice connection token"
    )

    attribute(:guild_id, :integer,
      allow_nil?: false,
      public?: true,
      description: "Guild ID this voice server update is for"
    )

    attribute(:endpoint, :string,
      allow_nil?: true,
      public?: true,
      description: "Voice server host"
    )

    create_timestamp(:inserted_at)
  end

  identities do
    identity :discord_id, [:guild_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  code_interface do
    define(:read)
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create voice server update event record from Discord data")
      primary?(true)

      argument(:data, AshDiscord.Consumer.Payloads.VoiceServerUpdateEvent,
        allow_nil?: false,
        description: "Discord voice server update event TypedStruct data"
      )

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :data) do
          %AshDiscord.Consumer.Payloads.VoiceServerUpdateEvent{} = data ->
            changeset
            |> Ash.Changeset.force_change_attribute(:token, data.token)
            |> Ash.Changeset.force_change_attribute(:guild_id, data.guild_id)
            |> maybe_set_endpoint(data.endpoint)

          _ ->
            Ash.Changeset.add_error(
              changeset,
              "Invalid data argument: expected VoiceServerUpdateEvent payload"
            )
        end
      end)

      upsert?(true)
      upsert_identity(:discord_id)
      upsert_fields([:token, :endpoint])
    end
  end

  defp maybe_set_endpoint(changeset, nil), do: changeset

  defp maybe_set_endpoint(changeset, endpoint) do
    Ash.Changeset.force_change_attribute(changeset, :endpoint, endpoint)
  end
end
