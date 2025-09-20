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
    discord_id = extract_discord_id(changeset)

    Logger.info("""
    API fetch attempted for Discord #{type} with ID: #{inspect(discord_id)}
    Consider using struct-first pattern with :discord_struct argument for better performance.
    """)

    case discord_id do
      nil ->
        {:error, "No Discord ID found for #{type} entity"}

      id ->
        case fetch_from_nostrum_api(type, id) do
          {:ok, entity} ->
            {:ok, entity}

          {:error, reason} ->
            {:error, "Failed to fetch #{type} with ID #{id}: #{inspect(reason)}"}
        end
    end
  end

  @doc """
  Fetches Discord entity from Nostrum API based on type and ID.
  """
  def fetch_from_nostrum_api(type, discord_id) do
    case type do
      :user ->
        Nostrum.Api.User.get(discord_id)

      :guild ->
        Nostrum.Api.Guild.get(discord_id)

      _ ->
        {:error, :unsupported_type}
    end
  end

  # Extract Discord ID from changeset attributes for API fetch
  defp extract_discord_id(changeset) do
    case Ash.Changeset.get_attribute(changeset, :discord_id) do
      nil -> nil
      discord_id -> discord_id
    end
  end
end
