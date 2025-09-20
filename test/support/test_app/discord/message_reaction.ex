defmodule TestApp.Discord.MessageReaction do
  @moduledoc """
  Test Discord MessageReaction resource for validating reaction transformations.
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:emoji_id, :integer,
      allow_nil?: true,
      public?: true
    )

    attribute(:emoji_name, :string,
      allow_nil?: true,
      public?: true
    )

    attribute(:count, :integer,
      allow_nil?: false,
      public?: true,
      default: 1
    )

    attribute(:me, :boolean,
      allow_nil?: true,
      public?: true,
      default: false
    )
  end

  actions do
    defaults([:read, :destroy])

    create :from_discord do
      description("Create message reaction from Discord data")
      primary?(true)

      argument(:discord_struct, :struct,
        allow_nil?: false,
        description: "Discord message reaction struct to transform"
      )

      change({AshDiscord.Changes.FromDiscord, type: :message_reaction})
    end

    update :update do
      primary?(true)
      accept([:emoji_id, :emoji_name, :count, :me])
    end
  end
end
