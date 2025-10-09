defmodule AshDiscord.Consumer.Handler.GuildMember do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec add(
          member_add :: Payloads.GuildMemberAdd.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(
        %Payloads.GuildMemberAdd{guild_id: guild_id, member: member},
        _ws_state,
        context
      ) do
    user_discord_id = member.user_id

    case Handler.invoke_configured_action(
           :GUILD_MEMBER_ADD,
           %{guild_discord_id: guild_id, user_discord_id: user_discord_id},
           %{
             guild_discord_id: guild_id,
             user_discord_id: user_discord_id,
             data: member,
             identity: %{guild_discord_id: guild_id, user_discord_id: user_discord_id}
           },
           context
         ) do
      {:ok, _member} ->
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to create guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec update(
          member_update :: Payloads.GuildMemberUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        %Payloads.GuildMemberUpdate{guild_id: guild_id, new_member: member},
        _ws_state,
        context
      ) do
    user_discord_id = member.user_id

    case Handler.invoke_configured_action(
           :GUILD_MEMBER_UPDATE,
           %{guild_discord_id: guild_id, user_discord_id: user_discord_id},
           %{
             guild_discord_id: guild_id,
             user_discord_id: user_discord_id,
             data: member,
             identity: %{guild_discord_id: guild_id, user_discord_id: user_discord_id}
           },
           context
         ) do
      {:ok, _member} ->
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to update guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec remove(
          member_remove :: Payloads.GuildMemberRemove.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(
        %Payloads.GuildMemberRemove{guild_id: guild_id, member: member},
        _ws_state,
        context
      ) do
    user_discord_id = member.user_id

    case Handler.invoke_configured_action(
           :GUILD_MEMBER_REMOVE,
           %{guild_discord_id: guild_id, user_discord_id: user_discord_id},
           %{},
           context
         ) do
      {:ok, _} ->
        Logger.info("Deleted guild member #{user_discord_id} from guild #{guild_id}")
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to delete guild member #{user_discord_id} from guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec chunk(
          chunk_event :: Payloads.GuildMembersChunkEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def chunk(%Payloads.GuildMembersChunkEvent{data: data}, _ws_state, context) do
    guild_id = Map.get(data, :guild_id)
    members = Map.get(data, :members, [])

    # Process each member in the chunk using invoke_configured_action
    results =
      Enum.map(members, fn member_data ->
        # Convert member data to Member payload
        case Payloads.Member.new(member_data) do
          {:ok, member_payload} ->
            user_id = member_payload.user_id

            # TODO: make the handler action take in a list of members for bulk processing
            Handler.invoke_configured_action(
              :GUILD_MEMBERS_CHUNK,
              %{guild_discord_id: guild_id, user_discord_id: user_id},
              %{
                guild_discord_id: guild_id,
                user_discord_id: user_id,
                data: member_payload,
                identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
              },
              context
            )

          {:error, error} ->
            Logger.warning(
              "Failed to convert member data to payload: #{inspect(error)}, data: #{inspect(member_data)}"
            )

            {:error, error}
        end
      end)

    # Check if any operations failed
    errors = Enum.filter(results, fn result -> match?({:error, _}, result) end)

    if Enum.empty?(errors) do
      :ok
    else
      Logger.warning("Failed to process #{length(errors)} members in chunk for guild #{guild_id}")

      :ok
    end
  end
end
