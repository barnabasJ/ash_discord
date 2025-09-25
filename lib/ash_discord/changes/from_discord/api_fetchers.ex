defmodule AshDiscord.Changes.FromDiscord.ApiFetchers do
  @moduledoc """
  API fallback functionality for Discord entity fetching.

  This module provides fallback capabilities when Discord data is not provided
  via the struct-first pattern. It uses Nostrum API calls to fetch Discord
  entities when only a Discord ID is available.

  ## Usage

  This module is used internally by `AshDiscord.Changes.FromDiscord` when no
  `:discord_struct` argument is provided. It attempts to extract Discord ID
  from changeset attributes and fetch the entity from Discord's API.

  ## Supported Entities

  Currently supports fetching:
  - Users via `Nostrum.Api.User.get/1`
  - Guilds via `Nostrum.Api.Guild.get/1`
  """

  require Logger

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
  """
  def fetch_from_nostrum_api(type, discord_id, changeset \\ nil) do
    case type do
      :user ->
        try do
          Nostrum.Api.User.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :guild ->
        try do
          Nostrum.Api.Guild.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :channel ->
        try do
          Nostrum.Api.Channel.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :webhook ->
        try do
          Nostrum.Api.Webhook.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :invite ->
        # Invite uses code instead of ID
        try do
          Nostrum.Api.Invite.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :sticker ->
        try do
          Nostrum.Api.Sticker.get(discord_id)
        rescue
          ArgumentError -> {:error, :api_unavailable}
        end

      :message ->
        # Message requires channel_id and message_id, can't fetch with just ID
        {:error, :requires_channel_id}

      :emoji ->
        # Emoji requires guild_id and emoji_id, can't fetch with just ID
        {:error, :requires_guild_id}

      :role ->
        # Role requires guild_id - try to get it from changeset if available
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

      :guild_member ->
        # GuildMember requires both guild_discord_id and user_discord_id
        if changeset do
          guild_discord_id = extract_guild_discord_id(changeset)
          user_discord_id = extract_user_discord_id(changeset)

          if guild_discord_id && user_discord_id do
            try do
              Nostrum.Api.Guild.member(guild_discord_id, user_discord_id)
            rescue
              ArgumentError -> {:error, :api_unavailable}
            end
          else
            {:error, :requires_guild_and_user_ids}
          end
        else
          {:error, :requires_guild_and_user_ids}
        end

      :message ->
        # Message requires channel_id and message_id, can't fetch with just ID
        # But we can use channel_discord_id argument if available
        if changeset do
          channel_id = extract_channel_discord_id(changeset)
          message_id = extract_discord_id(changeset)

          if channel_id && message_id do
            try do
              Nostrum.Api.Message.get(channel_id, message_id)
            rescue
              ArgumentError -> {:error, :api_unavailable}
            end
          else
            {:error, :requires_channel_and_message_ids}
          end
        else
          {:error, :requires_channel_and_message_ids}
        end

      _ ->
        {:error, :unsupported_type}
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
            {:ok, role_data}
        end

      {:error, reason} ->
        {:error, "Failed to fetch roles for guild #{guild_discord_id}: #{inspect(reason)}"}
    end
  end
end
