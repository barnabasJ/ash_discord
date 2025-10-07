defmodule AshDiscord.Consumer.Handler.Guild.Member do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec add(
          consumer :: module(),
          member_add :: Payloads.GuildMemberAdd.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(
        _consumer,
        %Payloads.GuildMemberAdd{guild_id: guild_id, member: member},
        _ws_state,
        context
      ) do
    case context.resource do
      nil ->
        :ok

      resource ->
        # Extract user_id from member struct
        user_discord_id = member.user_id || (member.user && member.user.id)

        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 data: member,
                 identity: %{guild_id: guild_id, user_id: user_discord_id}
               },
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _member} ->
            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to create guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
            )

            :ok
        end
    end
  end

  @spec update(
          consumer :: module(),
          member_update :: Payloads.GuildMemberUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        _consumer,
        %Payloads.GuildMemberUpdate{guild_id: guild_id, new_member: member},
        _ws_state,
        context
      ) do
    case context.resource do
      nil ->
        :ok

      resource ->
        user_discord_id = member.user_id

        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 data: member,
                 identity: %{guild_id: guild_id, user_id: user_discord_id}
               },
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _member} ->
            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to update guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
            )

            :ok
        end
    end
  end

  @spec remove(
          consumer :: module(),
          member_remove :: Payloads.GuildMemberRemove.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(
        _consumer,
        %Payloads.GuildMemberRemove{guild_id: guild_id, member: member},
        _ws_state,
        context
      ) do
    case context.resource do
      nil ->
        :ok

      resource ->
        user_discord_id = member.user_id

        query =
          resource
          |> Ash.Query.filter(user_id: user_discord_id, guild_id: guild_id)
          |> Ash.Query.set_context(%{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          })

        case Ash.bulk_destroy(query, :destroy, %{},
               return_errors?: true,
               return_records?: false
             ) do
          %Ash.BulkResult{status: :success} ->
            Logger.info("Deleted guild member #{user_discord_id} from guild #{guild_id}")
            :ok

          %Ash.BulkResult{status: :error, errors: errors} ->
            Logger.warning(
              "Failed to delete guild member #{user_discord_id} from guild #{guild_id}: #{inspect(errors)}"
            )

            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to delete guild member #{user_discord_id} from guild #{guild_id}: #{inspect(error)}"
            )

            :ok
        end
    end
  end

  @spec chunk(
          consumer :: module(),
          chunk_event :: Payloads.GuildMembersChunkEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def chunk(_consumer, _chunk_event, _ws_state, _context) do
    # GUILD_MEMBERS_CHUNK is an informational event sent in response to
    # Gateway Request Guild Members. It contains bulk member data but is
    # typically handled by Nostrum's caching layer.
    #
    # This handler exists to acknowledge the event and allow users to attach
    # their own side effects if needed, but by default we just return :ok.
    :ok
  end
end
