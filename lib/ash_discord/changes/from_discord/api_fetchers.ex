defmodule AshDiscord.Changes.FromDiscord.ApiFetchers do
  @moduledoc """
  API fallback functionality for Discord entity fetching.

  This module provides fallback capabilities when Discord data is not provided
  via the struct-first pattern. Currently implements placeholder functionality
  that encourages the struct-first approach, with structure prepared for future
  Nostrum API integration.

  ## Usage

  This module is used internally by `AshDiscord.Changes.FromDiscord` when no
  `:discord_struct` argument is provided. It attempts to extract Discord ID
  from changeset attributes and logs the attempt for monitoring.

  ## Future Implementation

  This module is structured to support future integration with Nostrum's API
  client for direct Discord data fetching when struct data is unavailable.
  """

  require Logger

  @doc """
  Attempts to fetch Discord entity data from API based on changeset and type.

  Currently returns an informative error encouraging struct-first pattern.
  Future implementation will integrate with Nostrum API client.

  ## Parameters

  - `changeset` - The Ash changeset being processed
  - `type` - The Discord entity type to fetch

  ## Returns

  - `{:error, reason}` - Currently always returns error encouraging struct pattern
  """
  def fetch_from_api(changeset, type) do
    discord_id = extract_discord_id(changeset)

    Logger.info("""
    API fetch attempted for Discord #{type} with ID: #{inspect(discord_id)}
    Consider using struct-first pattern with :discord_struct argument for better performance.
    """)

    {:error,
     """
     No Discord struct provided and API fetching not yet implemented.
     Please provide Discord data via :discord_struct argument.

     Example:
       MyResource.from_discord(%{
         discord_struct: your_discord_#{type}_struct
       })
     """}
  end

  # Extract Discord ID from changeset attributes for API fetch
  defp extract_discord_id(changeset) do
    case Ash.Changeset.get_attribute(changeset, :discord_id) do
      nil -> nil
      discord_id -> discord_id
    end
  end
end
