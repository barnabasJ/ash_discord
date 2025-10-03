defmodule AshDiscord.Consumer.Handler.Invite do
  require Logger

  @spec create(
          consumer :: module(),
          invite :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def create(consumer, invite, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(consumer) do
      {:ok, resource} ->
        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 discord_struct: invite
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
          invite_data :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def delete(consumer, invite_data, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(consumer) do
      {:ok, resource} ->
        # Try to find and delete the invite by code
        case resource
             |> Ash.Query.for_read(:read)
             |> Ash.Query.filter(code: invite_data.code)
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
            Logger.warning("AshDiscord: Invite not found for deletion: #{invite_data.code}")
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
