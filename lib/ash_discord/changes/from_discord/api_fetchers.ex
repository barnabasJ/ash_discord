defmodule AshDiscord.Changes.FromDiscord.ApiFetchers do
  @moduledoc """
  API fallback functionality for Discord entity fetching.

  This module provides fallback capabilities when Discord data is not provided
  via the struct-first pattern. It uses Nostrum API calls to fetch Discord
  entities when only a Discord ID is available.

  Returns TypedStruct payloads instead of raw Nostrum structs.

  ## Usage

  This module is used internally by `AshDiscord.Changes.FromDiscord.*` modules
  to fetch entities from Discord's API using identity values.

  ## Supported Entities

  Currently supports fetching:
  - Users via `Nostrum.Api.User.get/1`
  - Guilds via `Nostrum.Api.Guild.get/1`
  - And more...
  """

  require Logger

  alias AshDiscord.Consumer.Payloads

  @doc """
  Fetches a Discord user by ID and returns a TypedStruct.
  """
  def fetch_user(nil), do: {:error, "User ID is required for API fallback"}

  def fetch_user(discord_id) when is_integer(discord_id) do
    fetch_from_nostrum_api(:user, discord_id)
  end

  @doc """
  Fetches a Discord guild by ID and returns a TypedStruct.
  """
  def fetch_guild(nil), do: {:error, "Guild ID is required for API fallback"}

  def fetch_guild(discord_id) when is_integer(discord_id) do
    fetch_from_nostrum_api(:guild, discord_id)
  end

  @doc """
  Fetches a Discord channel by ID and returns a TypedStruct.
  """
  def fetch_channel(nil), do: {:error, "Channel ID is required for API fallback"}

  def fetch_channel(discord_id) when is_integer(discord_id) do
    fetch_from_nostrum_api(:channel, discord_id)
  end

  @doc """
  Fetches a Discord guild member by guild and user ID and returns a TypedStruct.
  """
  def fetch_member(%{guild_id: guild_id, user_id: user_id}) do
    case Nostrum.Api.Guild.member(guild_id, user_id) do
      {:ok, nostrum_member} -> {:ok, Payloads.Member.new(nostrum_member)}
      error -> error
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  @doc """
  Fetches a Discord message by channel and message ID and returns a TypedStruct.
  """
  def fetch_message(%{channel_id: channel_id, message_id: message_id}) do
    case Nostrum.Api.Message.get(channel_id, message_id) do
      {:ok, nostrum_message} -> {:ok, Payloads.Message.new(nostrum_message)}
      error -> error
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  def fetch_message(_invalid_identity) do
    {:error, :requires_channel_and_message_ids}
  end

  @doc """
  Attempts to fetch Discord entity data from Nostrum cache based on changeset and type.

  Leverages Nostrum's built-in caching system to provide fallback data when
  `:discord_struct` is not provided. Falls back gracefully with informative
  errors encouraging struct-first pattern for best performance.

  ## Parameters

  - `changeset` - The Ash changeset being processed
  - `type` - The Discord entity type to fetch

  ## Returns

  - `{:ok, discord_data}` - Successfully fetched from Nostrum cache
  - `{:error, reason}` - Cache miss or fetching disabled
  """
  def fetch_from_api(changeset, type) do
    # Special handling for entities that don't have discord_id fields or aren't API-fetchable
    cond do
      type == :guild_member ->
        fetch_guild_member_from_api(changeset)

      type == :invite ->
        fetch_invite_from_api(changeset)

      type in [:typing_indicator, :message_reaction] ->
        # These are event-based entities, not persistent Discord entities
        # They should always be created from provided data, not fetched from API
        {:error,
         "#{type} entities cannot be fetched from Discord API - they are event-based. Please provide discord_struct argument."}

      true ->
        discord_id = extract_discord_id(changeset)

        Logger.info("""
        API fetch attempted for Discord #{type} with ID: #{inspect(discord_id)}
        Consider using struct-first pattern with :discord_struct argument for better performance.
        """)

        case discord_id do
          nil ->
            {:error, "No Discord ID found for #{type} entity"}

          id ->
            case fetch_from_nostrum_api(type, id, changeset) do
              {:ok, entity} ->
                {:ok, entity}

              {:error, reason} ->
                {:error, "Failed to fetch #{type} with ID #{id}: #{inspect(reason)}"}
            end
        end
    end
  end

  # Special handler for guild_member API fetch
  defp fetch_guild_member_from_api(changeset) do
    guild_discord_id = extract_guild_discord_id(changeset)
    user_discord_id = extract_user_discord_id(changeset)

    Logger.info("""
    API fetch attempted for Discord guild_member with IDs:
    user: #{inspect(user_discord_id)}, guild: #{inspect(guild_discord_id)}
    Consider using struct-first pattern with :discord_struct argument for better performance.
    """)

    if guild_discord_id && user_discord_id do
      case fetch_from_nostrum_api(:guild_member, nil, changeset) do
        {:ok, entity} ->
          {:ok, entity}

        {:error, reason} ->
          {:error, "Failed to fetch guild_member: #{inspect(reason)}"}
      end
    else
      {:error, "No Discord ID found for guild_member entity"}
    end
  end

  # Special handler for invite API fetch
  defp fetch_invite_from_api(changeset) do
    invite_code = extract_invite_code(changeset)

    Logger.info("""
    API fetch attempted for Discord invite with code: #{inspect(invite_code)}
    Consider using struct-first pattern with :discord_struct argument for better performance.
    """)

    if invite_code do
      case fetch_from_nostrum_api(:invite, invite_code, changeset) do
        {:ok, entity} ->
          {:ok, entity}

        {:error, reason} ->
          {:error, "Failed to fetch invite: #{inspect(reason)}"}
      end
    else
      {:error, "No invite code found for invite entity"}
    end
  end

  # Extract invite code from changeset arguments or attributes
  defp extract_invite_code(changeset) do
    case Ash.Changeset.get_argument(changeset, :code) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :code) do
          nil -> nil
          code -> code
        end

      code ->
        code
    end
  end

  @doc """
  Fetches Discord entity from Nostrum API based on type and ID.
  Returns TypedStruct payloads.
  """
  def fetch_from_nostrum_api(type, discord_id, changeset \\ nil) do
    case type do
      :user -> fetch_simple_entity(&Nostrum.Api.User.get/1, discord_id, :user)
      :guild -> fetch_simple_entity(&Nostrum.Api.Guild.get/1, discord_id, :guild)
      :channel -> fetch_simple_entity(&Nostrum.Api.Channel.get/1, discord_id, :channel)
      # TODO: Add Webhook TypedStruct
      :webhook -> {:error, :not_implemented}
      # TODO: Add Invite TypedStruct
      :invite -> {:error, :not_implemented}
      :sticker -> fetch_simple_entity(&Nostrum.Api.Sticker.get/1, discord_id, :sticker)
      # Emoji requires guild context
      :emoji -> {:error, :requires_guild_id}
      :role -> fetch_role_entity(changeset, discord_id)
      :guild_member -> fetch_guild_member_entity(changeset)
      :message -> fetch_message_entity(changeset)
      _ -> {:error, :unsupported_type}
    end
  end

  # Fetches a simple entity that only requires an ID and wraps in TypedStruct
  defp fetch_simple_entity(api_function, discord_id, type) do
    try do
      case api_function.(discord_id) do
        {:ok, nostrum_struct} ->
          case wrap_in_typed_struct(type, nostrum_struct) do
            {:error, _} = error -> error
            typed_struct -> {:ok, typed_struct}
          end

        error ->
          error
      end
    rescue
      ArgumentError -> {:error, :api_unavailable}
    end
  end

  # Fetches role entity which requires guild context
  defp fetch_role_entity(changeset, discord_id) do
    if changeset do
      guild_discord_id = extract_guild_discord_id(changeset)

      if guild_discord_id do
        fetch_role_from_guild(guild_discord_id, discord_id)
      else
        {:error, :requires_guild_id}
      end
    else
      {:error, :requires_guild_id}
    end
  end

  # Fetches guild_member entity which requires both guild and user IDs
  defp fetch_guild_member_entity(changeset) do
    if changeset do
      guild_discord_id = extract_guild_discord_id(changeset)
      user_discord_id = extract_user_discord_id(changeset)

      if guild_discord_id && user_discord_id do
        try do
          case Nostrum.Api.Guild.member(guild_discord_id, user_discord_id) do
            {:ok, nostrum_member} -> {:ok, Payloads.Member.new(nostrum_member)}
            error -> error
          end
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end
      else
        {:error, :requires_guild_and_user_ids}
      end
    else
      {:error, :requires_guild_and_user_ids}
    end
  end

  # Fetches message entity which requires channel and message IDs
  defp fetch_message_entity(changeset) do
    if changeset do
      channel_id = extract_channel_discord_id(changeset)
      message_id = extract_discord_id(changeset)

      if channel_id && message_id do
        try do
          case Nostrum.Api.Message.get(channel_id, message_id) do
            {:ok, nostrum_message} -> {:ok, Payloads.Message.new(nostrum_message)}
            error -> error
          end
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end
      else
        {:error, :requires_channel_and_message_ids}
      end
    else
      {:error, :requires_channel_and_message_ids}
    end
  end

  # Extract Discord ID from changeset arguments or attributes for API fetch
  defp extract_discord_id(changeset) do
    case Ash.Changeset.get_argument(changeset, :discord_id) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :discord_id) do
          nil -> nil
          discord_id -> discord_id
        end

      discord_id ->
        discord_id
    end
  end

  # Extract guild Discord ID from changeset arguments or attributes
  defp extract_guild_discord_id(changeset) do
    case Ash.Changeset.get_argument(changeset, :guild_discord_id) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :guild_discord_id) do
          nil -> nil
          guild_discord_id -> guild_discord_id
        end

      guild_discord_id ->
        guild_discord_id
    end
  end

  # Extract user Discord ID from changeset arguments or attributes
  defp extract_user_discord_id(changeset) do
    case Ash.Changeset.get_argument(changeset, :user_discord_id) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :user_discord_id) do
          nil -> nil
          user_discord_id -> user_discord_id
        end

      user_discord_id ->
        user_discord_id
    end
  end

  # Extract channel Discord ID from changeset arguments or attributes
  defp extract_channel_discord_id(changeset) do
    case Ash.Changeset.get_argument(changeset, :channel_discord_id) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :channel_discord_id) do
          nil -> nil
          channel_discord_id -> channel_discord_id
        end

      channel_discord_id ->
        channel_discord_id
    end
  end

  # Fetch role data by getting the guild and finding the specific role
  defp fetch_role_from_guild(guild_discord_id, role_discord_id) do
    case Nostrum.Api.Guild.roles(guild_discord_id) do
      {:ok, roles} ->
        case Enum.find(roles, fn role -> role.id == role_discord_id end) do
          nil ->
            {:error, "Role #{role_discord_id} not found in guild #{guild_discord_id}"}

          role_data ->
            {:ok, Payloads.Role.new(role_data)}
        end

      {:error, reason} ->
        {:error, "Failed to fetch roles for guild #{guild_discord_id}: #{inspect(reason)}"}
    end
  end

  # Wraps Nostrum structs in appropriate TypedStruct payloads
  # Note: Payloads.*.new/1 returns {:ok, struct} or {:error, error}, so we unwrap it
  defp wrap_in_typed_struct(type, nostrum_struct) do
    result =
      case type do
        :user -> Payloads.User.new(nostrum_struct)
        :guild -> Payloads.Guild.new(nostrum_struct)
        :channel -> Payloads.Channel.new(nostrum_struct)
        :message -> Payloads.Message.new(nostrum_struct)
        :role -> Payloads.Role.new(nostrum_struct)
        :member -> Payloads.Member.new(nostrum_struct)
        :sticker -> Payloads.Sticker.new(nostrum_struct)
        :emoji -> Payloads.Emoji.new(nostrum_struct)
        _ -> {:ok, nostrum_struct}
      end

    case result do
      {:ok, typed_struct} -> typed_struct
      {:error, _} = error -> error
    end
  end
end
