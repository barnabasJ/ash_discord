defmodule AshDiscord.Consumer.Handler.Guild.Member do
  require Logger
  require Ash.Query

  @spec add(
          consumer :: module(),
          {guild_id :: integer(), new_member :: Nostrum.Struct.Guild.Member.t()},
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def add(consumer, {guild_id, member}, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(consumer) do
      {:ok, resource} ->
        # Extract user_id from member struct
        user_discord_id = member.user_id || (member.user && member.user.id)

        try do
          _member =
            resource
            |> Ash.Changeset.for_create(
              :from_discord,
              %{
                user_discord_id: user_discord_id,
                guild_discord_id: guild_id,
                discord_struct: member
              },
              context: %{
                private: %{ash_discord?: true},
                shared: %{private: %{ash_discord?: true}}
              }
            )
            |> Ash.create!()

          :ok
        rescue
          error ->
            Logger.warning(
              "Failed to create guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end

      :error ->
        # No guild member resource configured
        :ok
    end
  end

  @spec update(
          consumer :: module(),
          {guild_id :: integer(), old_member :: Nostrum.Struct.Guild.Member.t() | nil,
           new_member :: Nostrum.Struct.Guild.Member.t()},
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(consumer, {guild_id, _old_member, member}, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(consumer) do
      {:ok, resource} ->
        user_discord_id = member.user_id

        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{
                 user_discord_id: user_discord_id,
                 guild_discord_id: guild_id,
                 discord_struct: member
               },
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _} ->
            :ok

          error ->
            Logger.warning(
              "Failed to update guild member #{user_discord_id} in guild #{guild_id}: #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end

      :error ->
        # No guild member resource configured
        :ok
    end
  end

  @spec remove(
          consumer :: module(),
          {guild_id :: integer(), old_member :: Nostrum.Struct.Guild.Member.t()},
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def remove(consumer, {guild_id, member}, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(consumer) do
      {:ok, resource} ->
        user_discord_id = member.user_id

        query =
          resource
          |> Ash.Query.filter(user_discord_id: user_discord_id, guild_id: guild_id)

        case Ash.bulk_destroy!(query, :destroy, %{},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               },
               return_errors?: false,
               return_records?: false
             ) do
          %Ash.BulkResult{status: :success} ->
            Logger.info("Deleted guild member #{user_discord_id} from guild #{guild_id}")
            :ok

          error ->
            Logger.warning(
              "Failed to delete guild member #{user_discord_id} from guild #{guild_id}: #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end

      :error ->
        # No guild member resource configured
        :ok
    end
  end
end
