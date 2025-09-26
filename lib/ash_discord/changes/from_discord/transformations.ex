defmodule AshDiscord.Changes.FromDiscord.Transformations do
  @moduledoc """
  Shared transformation utilities for Discord entity processing.

  This module provides reusable functions for common transformation patterns
  across Discord entities, including datetime parsing, email generation, and
  relationship management with auto-creation capabilities.

  ## Usage

  These functions are designed to be used within `AshDiscord.Changes.FromDiscord`
  transformation functions to handle common patterns consistently across all
  Discord entity types.

  ## Key Features

  - **Graceful datetime parsing**: Handles nil, empty, and invalid datetime formats
  - **Discord email generation**: Consistent email format for Discord users
  - **Relationship management**: Auto-creation patterns for related entities
  - **Error tolerance**: Robust handling of malformed or missing data

  ## Examples

      # Datetime transformation
      changeset = set_datetime_field(changeset, :joined_at, discord_data.joined_at)

      # Email generation
      changeset = set_discord_email(changeset, discord_data.id)

      # Relationship management
      changeset = manage_guild_relationship(changeset, discord_data.guild_id)

  """

  @doc """
  Sets a datetime field on the changeset with graceful error handling.

  Handles various datetime formats and provides fallbacks for invalid data:
  - Valid ISO8601 strings are parsed to DateTime
  - nil values are preserved as nil
  - Empty strings are converted to nil
  - Invalid formats are logged and converted to nil

  ## Parameters

  - `changeset` - The Ash changeset to modify
  - `field` - The datetime field to set
  - `datetime_value` - The datetime value to parse (string, DateTime, or nil)

  ## Returns

  Updated changeset with the datetime field set, or unchanged if parsing fails.

  ## Examples

      # Valid datetime string
      changeset = set_datetime_field(changeset, :joined_at, "2023-01-01T12:00:00Z")

      # Handles nil gracefully
      changeset = set_datetime_field(changeset, :premium_since, nil)

      # Invalid format logs warning and sets nil
      changeset = set_datetime_field(changeset, :created_at, "invalid-date")

  """
  def set_datetime_field(changeset, field, datetime_value) do
    case parse_datetime(datetime_value) do
      {:ok, datetime} ->
        Ash.Changeset.force_change_attribute(changeset, field, datetime)

      {:error, reason} ->
        require Logger
        Logger.warning("Failed to parse datetime for field #{field}: #{reason}. Setting to nil.")
        Ash.Changeset.force_change_attribute(changeset, field, nil)

      nil ->
        Ash.Changeset.force_change_attribute(changeset, field, nil)
    end
  end

  @doc """
  Generates a placeholder Discord email address for a given Discord ID.

  **Why we need this**: Discord's API does not provide email addresses when fetching
  user data via `Nostrum.Api.User.get/1`. However, many applications require an email
  field for user records. This function creates consistent placeholder email addresses
  using the pattern: `discord+{discord_id}@{domain}`

  The default domain can be configured via application configuration to match your
  application's needs (e.g., "steward.local" for Steward, "discord.local" for others).

  ## Parameters

  - `discord_id` - The Discord user ID (integer or string)
  - `domain` - Optional custom domain (defaults to configured or "discord.local")

  ## Configuration

      config :ash_discord, :email_domain, "steward.local"

  ## Returns

  String placeholder email address in the format `discord+{discord_id}@{domain}`

  ## Examples

      iex> generate_discord_email(123456789)
      "discord+123456789@discord.local"

      iex> generate_discord_email("987654321", "custom.domain")
      "discord+987654321@custom.domain"

  """
  def generate_discord_email(discord_id, domain \\ nil) do
    email_domain = domain || Application.get_env(:ash_discord, :email_domain, "discord.local")
    "discord+#{discord_id}@#{email_domain}"
  end

  @doc """
  Sets the Discord placeholder email field on a changeset using the Discord ID.

  Convenience function that combines Discord placeholder email generation with changeset
  modification. Since Discord's API doesn't provide email addresses for users, this
  creates a consistent placeholder email that applications can use for user records.

  ## Parameters

  - `changeset` - The Ash changeset to modify
  - `discord_id` - The Discord ID to use for placeholder email generation

  ## Returns

  Updated changeset with the email field set to the generated placeholder Discord email.

  ## Examples

      changeset = set_discord_email(changeset, 123456789)
      # Sets email to "discord+123456789@discord.local" (or configured domain)

  """
  def set_discord_email(changeset, discord_id) do
    email = generate_discord_email(discord_id)
    Ash.Changeset.force_change_attribute(changeset, :email, email)
  end

  @doc """
  Manages guild relationship with auto-creation capabilities.

  Sets up relationship management for guild associations using Ash's
  relationship management features with auto-creation when the related
  guild doesn't exist.

  ## Parameters

  - `changeset` - The Ash changeset to modify
  - `guild_id` - The Discord guild ID to associate

  ## Returns

  Updated changeset with guild relationship managed.

  ## Examples

      changeset = manage_guild_relationship(changeset, discord_data.guild_id)

  """
  def manage_guild_relationship(changeset, guild_id) when not is_nil(guild_id) do
    Ash.Changeset.manage_relationship(changeset, :guild, guild_id,
      type: :append_and_remove,
      use_identities: [:unique_discord_id],
      value_is_key: :discord_id,
      on_no_match: {:create, :from_discord}
    )
  end

  def manage_guild_relationship(changeset, _nil_guild_id), do: changeset

  @doc """
  Manages user relationship with auto-creation capabilities.

  Sets up relationship management for user associations using Ash's
  relationship management features with auto-creation when the related
  user doesn't exist.

  ## Parameters

  - `changeset` - The Ash changeset to modify
  - `user_id` - The Discord user ID to associate
  - `relationship_name` - Optional relationship name (defaults to :user)

  ## Returns

  Updated changeset with user relationship managed.

  ## Examples

      changeset = manage_user_relationship(changeset, discord_data.user_id)
      changeset = manage_user_relationship(changeset, discord_data.author.id, :author)

  """
  def manage_user_relationship(changeset, user_id, relationship_name \\ :user)

  def manage_user_relationship(changeset, user_id, relationship_name) when not is_nil(user_id) do
    Ash.Changeset.manage_relationship(changeset, relationship_name, user_id,
      type: :append_and_remove,
      use_identities: [:discord_id],
      value_is_key: :discord_id,
      on_no_match: {:create, :from_discord}
    )
  end

  def manage_user_relationship(changeset, _nil_user_id, _relationship_name), do: changeset

  @doc """
  Manages channel relationship with auto-creation capabilities.

  Sets up relationship management for channel associations using Ash's
  relationship management features with auto-creation when the related
  channel doesn't exist.

  ## Parameters

  - `changeset` - The Ash changeset to modify
  - `channel_id` - The Discord channel ID to associate

  ## Returns

  Updated changeset with channel relationship managed.

  ## Examples

      changeset = manage_channel_relationship(changeset, discord_data.channel_id)

  """
  def manage_channel_relationship(changeset, channel_id) when not is_nil(channel_id) do
    Ash.Changeset.manage_relationship(changeset, :channel, channel_id,
      type: :append_and_remove,
      use_identities: [:discord_id],
      value_is_key: :discord_id,
      on_no_match: {:create, :from_discord}
    )
  end

  def manage_channel_relationship(changeset, _nil_channel_id), do: changeset

  @doc """
  Transforms Discord permission overwrites to a standardized map format.

  Converts Discord permission overwrite data structures into a consistent
  format suitable for storage and processing. Handles both individual
  overwrites and lists of overwrites.

  ## Parameters

  - `permission_overwrites` - Discord permission overwrites data (list or single overwrite)

  ## Returns

  List of maps with standardized permission overwrite format:
  ```
  %{
    "id" => string,          # Target ID (user or role)
    "type" => integer,       # 0 = role, 1 = member
    "allow" => string,       # Allowed permissions bitfield as string
    "deny" => string         # Denied permissions bitfield as string
  }
  ```

  ## Examples

      iex> transform_permission_overwrites([%{id: 123, type: 0, allow: 1024, deny: 0}])
      [%{"id" => "123", "type" => 0, "allow" => "1024", "deny" => "0"}]

      iex> transform_permission_overwrites(nil)
      []

  """
  def transform_permission_overwrites(nil), do: []
  def transform_permission_overwrites([]), do: []

  def transform_permission_overwrites(overwrites) when is_list(overwrites) do
    Enum.map(overwrites, &transform_single_overwrite/1)
  end

  def transform_permission_overwrites(single_overwrite) when is_map(single_overwrite) do
    [transform_single_overwrite(single_overwrite)]
  end

  def transform_permission_overwrites(_invalid), do: []

  # Private helper functions

  # Transforms a single permission overwrite to standardized format
  defp transform_single_overwrite(overwrite) do
    %{
      "id" => overwrite.id || overwrite["id"],
      "type" => overwrite.type || overwrite["type"] || 0,
      "allow" => to_string(overwrite.allow || overwrite["allow"] || 0),
      "deny" => to_string(overwrite.deny || overwrite["deny"] || 0)
    }
  end

  # Parses datetime values with comprehensive error handling
  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil

  defp parse_datetime(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, parsed_datetime, _offset} -> {:ok, parsed_datetime}
      {:error, reason} -> {:error, "Invalid datetime format: #{reason}"}
    end
  end

  defp parse_datetime(%DateTime{} = datetime), do: {:ok, datetime}

  defp parse_datetime(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp, :second) do
      {:ok, datetime} -> {:ok, datetime}
      {:error, reason} -> {:error, "Invalid Unix timestamp: #{reason}"}
    end
  end

  defp parse_datetime(other), do: {:error, "Unsupported datetime type: #{inspect(other)}"}
end
