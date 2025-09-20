defmodule TestApp.Discord.Message do
  @moduledoc """
  Test Message resource for AshDiscord testing.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute(:discord_id, :integer, allow_nil?: false, public?: true)
    attribute(:content, :string, allow_nil?: true, public?: true)
    attribute(:channel_id, :integer, public?: true)
    attribute(:author_id, :integer, public?: true)
    attribute(:guild_id, :integer, public?: true)
    attribute(:timestamp, :utc_datetime, public?: true)
    attribute(:edited_timestamp, :utc_datetime, public?: true)
    attribute(:tts, :boolean, public?: true, default: false)
    attribute(:mention_everyone, :boolean, public?: true, default: false)
    attribute(:pinned, :boolean, public?: true, default: false)

    timestamps()
  end

  identities do
    identity(:unique_discord_id, [:discord_id], pre_check_with: TestApp.Domain)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:discord_id, :content, :channel_id, :author_id, :guild_id])

      argument(:message, :string)
      argument(:channel, :string)

      change(fn changeset, _context ->
        message = Ash.Changeset.get_argument(changeset, :message)
        channel = Ash.Changeset.get_argument(changeset, :channel)

        changeset =
          if message,
            do: Ash.Changeset.change_attribute(changeset, :content, message),
            else: changeset

        changeset =
          if channel,
            do: Ash.Changeset.change_attribute(changeset, :channel_id, channel),
            else: changeset

        changeset
      end)
    end

    create :from_discord do
      accept([
        :discord_id,
        :content,
        :channel_id,
        :author_id,
        :guild_id,
        :timestamp,
        :edited_timestamp,
        :tts,
        :mention_everyone,
        :pinned
      ])

      upsert?(true)
      upsert_identity(:unique_discord_id)

      upsert_fields([
        :content,
        :channel_id,
        :author_id,
        :guild_id,
        :timestamp,
        :edited_timestamp,
        :tts,
        :mention_everyone,
        :pinned
      ])

      argument(:discord_struct, :struct, description: "Discord message data to transform")

      change({AshDiscord.Changes.FromDiscord, type: :message})
    end

    read :search do
      argument(:query, :string, allow_nil?: false)
      argument(:limit, :integer, default: 10)

      filter(expr(contains(content, ^arg(:query))))

      prepare(fn query, _context ->
        case Ash.Query.get_argument(query, :limit) do
          limit when is_integer(limit) -> Ash.Query.limit(query, limit)
          _ -> query
        end
      end)
    end

    create :hello do
      change(fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:content, "Hello from AshDiscord!")
        |> Ash.Changeset.change_attribute(:discord_id, System.system_time(:nanosecond))
        |> Ash.Changeset.change_attribute(:channel_id, 123_456_789)
        |> Ash.Changeset.change_attribute(:author_id, 987_654_321)
      end)
    end
  end

  relationships do
    belongs_to(:guild, TestApp.Discord.Guild,
      destination_attribute: :discord_id,
      source_attribute: :guild_id
    )

    belongs_to(:user, TestApp.Discord.User,
      destination_attribute: :discord_id,
      source_attribute: :author_id
    )
  end

  code_interface do
    define(:create)
    define(:from_discord)
    define(:search)
    define(:hello)
    define(:read)
  end
end
