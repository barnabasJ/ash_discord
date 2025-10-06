defmodule TestApp.Discord.GuildScheduledEventUser do
  @moduledoc """
  Test GuildScheduledEventUser resource for AshDiscord testing.

  This resource tracks user subscriptions to scheduled events. It's primarily
  used for tracing handler execution for informational events (USER_ADD/USER_REMOVE).
  """

  use Ash.Resource,
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:guild_scheduled_event_id, :integer, allow_nil?: false, public?: true)
    attribute(:user_id, :integer, allow_nil?: false, public?: true)
    attribute(:guild_id, :integer, allow_nil?: false, public?: true)

    timestamps()
  end

  identities do
    identity(:event_user, [:guild_scheduled_event_id, :user_id], pre_check_with: TestApp.Discord)
  end

  actions do
    defaults([:read, :destroy, :create])

    update :update do
      primary?(true)
      accept([])
    end
  end

  code_interface do
    define(:create)
    define(:update)
    define(:read)
    define(:destroy)
  end
end
