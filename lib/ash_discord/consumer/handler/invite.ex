defmodule AshDiscord.Consumer.Handler.Invite do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          consumer :: module(),
          invite_create :: Payloads.InviteCreateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def create(consumer, invite, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(consumer) do
      {:ok, resource} ->
        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 data: invite
               },
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _invite} ->
            Logger.info("AshDiscord: Invite created successfully")
            :ok

          {:error, error} ->
            Logger.error("AshDiscord: Failed to create invite: #{inspect(error)}")
            {:error, error}
        end

      :error ->
        Logger.warning("No invite resource configured")
        {:error, "No invite resource configured"}
    end
  end

  @spec delete(
          consumer :: module(),
          invite_delete :: Payloads.InviteDeleteEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def delete(consumer, invite_delete, _ws_state, _context) do
    code = invite_delete.code

    case AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(consumer) do
      {:ok, resource} ->
        # Try to find and delete the invite by code
        case resource
             |> Ash.Query.for_read(:read)
             |> Ash.Query.filter(code: code)
             |> Ash.Query.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.read_one() do
          {:ok, invite} when not is_nil(invite) ->
            case Ash.destroy(invite, actor: %{role: :bot}) do
              :ok ->
                Logger.info("AshDiscord: Invite deleted successfully")
                :ok

              {:error, error} ->
                Logger.error("AshDiscord: Failed to delete invite: #{inspect(error)}")
                {:error, error}
            end

          {:ok, nil} ->
            Logger.warning("AshDiscord: Invite not found for deletion: #{code}")
            :ok

          {:error, error} ->
            Logger.error("AshDiscord: Failed to find invite for deletion: #{inspect(error)}")
            {:error, error}
        end

      :error ->
        Logger.warning("No invite resource configured")
        :ok
    end
  end
end
