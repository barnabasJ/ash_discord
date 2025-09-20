defmodule TestApp.Discord.VoiceState do
  @moduledoc """
  Test Discord VoiceState resource for validating voice state transformations.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:user_id, :integer,
      allow_nil?: false,
      public?: true
    )

    attribute(:channel_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:guild_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:session_id, :string,
      allow_nil?: false,
      public?: true
    )

    attribute(:deaf, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:mute, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:self_deaf, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:self_mute, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:self_stream, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:self_video, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:suppress, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )

    attribute(:request_to_speak_timestamp, :utc_datetime,
      allow_nil?: true,
      public?: true
    )
  end

  identities do
    identity :user_guild, [:user_id, :guild_id] do
      pre_check_with(TestApp.Discord)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create voice state from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: false,
        description: "Discord voice state struct to transform"
      )

      change({AshDiscord.Changes.FromDiscord, type: :voice_state})

      upsert?(true)
      upsert_identity(:user_guild)

      upsert_fields([
        :channel_id,
        :guild_id,
        :session_id,
        :deaf,
        :mute,
        :self_deaf,
        :self_mute,
        :self_stream,
        :self_video,
        :suppress,
        :request_to_speak_timestamp
      ])
    end

    update :update do
      primary?(true)

      accept([
        :channel_id,
        :guild_id,
        :session_id,
        :deaf,
        :mute,
        :self_deaf,
        :self_mute,
        :self_stream,
        :self_video,
        :suppress,
        :request_to_speak_timestamp
      ])
    end
  end
end
