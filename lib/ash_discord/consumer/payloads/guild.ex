defmodule AshDiscord.Consumer.Payloads.Guild do
  @moduledoc """
  TypedStruct wrapper for Discord Guild data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The guild's id"
    field :name, :string, allow_nil?: false, description: "The name of the guild"
    field :icon, :string, description: "The hash of the guild's icon"
    field :splash, :string, description: "The hash of the guild's splash"
    field :owner_id, :integer, description: "The id of the guild owner"
    field :region, :string, description: "The id of the voice region"
    field :afk_channel_id, :integer, description: "The id of the guild's afk channel"
    field :afk_timeout, :integer, description: "The time someone must be afk before being moved"
    field :verification_level, :integer, description: "The level of verification"

    field :default_message_notifications, :integer,
      description: "Default message notifications level"

    field :explicit_content_filter, :integer, description: "Explicit content filter level"
    field :roles, :map, description: "Map of role id to role"
    field :emojis, {:array, :map}, description: "List of emojis"
    field :features, {:array, :string}, description: "List of guild features"
    field :mfa_level, :integer, description: "Required MFA level of the guild"

    field :application_id, :integer,
      description: "Application id of the guild creator if bot created"

    field :widget_enabled, :boolean, description: "Whether or not the server widget is enabled"
    field :widget_channel_id, :integer, description: "The channel id for the server widget"

    field :system_channel_id, :integer,
      description: "The id of the channel to which system messages are sent"

    field :rules_channel_id, :integer,
      description: "The id of the channel used for rules (PUBLIC guilds only)"

    field :public_updates_channel_id, :integer,
      description: "The id of the channel where admins receive notices (PUBLIC guilds only)"

    field :safety_alerts_channel_id, :integer,
      description: "The id of the channel for safety alerts"

    field :joined_at, :string, description: "Date the bot user joined the guild"
    field :large, :boolean, description: "Whether the guild is considered 'large'"
    field :unavailable, :boolean, description: "Whether the guild is available"
    field :member_count, :integer, description: "Total number of members in the guild"
    field :voice_states, {:array, :map}, description: "List of voice states"
    field :channels, :map, description: "Map of channel id to channel"
    field :guild_scheduled_events, {:array, :map}, description: "List of scheduled events"
    field :vanity_url_code, :string, description: "Guild invite vanity URL"
    field :threads, {:array, :map}, description: "All active threads in the guild"
    field :stickers, {:array, :map}, description: "Custom stickers for this guild"
    field :discovery_splash, :string, description: "The hash of the guild's discovery splash"
    field :system_channel_flags, :integer, description: "System channel flags"
    field :max_presences, :integer, description: "Maximum number of presences for the guild"
    field :max_members, :integer, description: "Maximum number of members for the guild"
    field :description, :string, description: "The description for the guild"
    field :banner, :string, description: "The hash of the guild's banner"
    field :premium_tier, :integer, description: "Premium tier (Server Boost level)"
    field :premium_subscription_count, :integer, description: "Number of boosts this guild has"

    field :preferred_locale, :string,
      description: "The preferred locale of a guild with PUBLIC feature"

    field :max_video_channel_users, :integer,
      description: "Max amount of users in a video channel"

    field :max_stage_video_channel_users, :integer,
      description: "Max amount of users in a stage video channel"

    field :welcome_screen, :map, description: "The welcome screen configuration"
    field :nsfw_level, :integer, description: "Guild NSFW level"

    field :premium_progress_bar_enabled, :boolean,
      description: "Whether the guild has the boost progress bar enabled"
  end

  @doc """
  Create a Guild TypedStruct from a Nostrum Guild struct.

  Accepts a `Nostrum.Struct.Guild.t()` and creates an AshDiscord Guild TypedStruct.
  If already a Payloads.Guild struct, returns it as-is.
  """
  # TODO: This clause shouldn't be necessary - Ash's type system should handle this.
  # When we pass %Payloads.Guild{} to Ash.Changeset.for_create(..., %{data: guild}),
  # Ash calls cast_input/2 which calls .new() again. This should be a no-op for
  # already-typed data. Investigate if Ash.TypedStruct can handle this automatically.
  def new(%__MODULE__{} = guild) do
    {:ok, guild}
  end

  def new(%Nostrum.Struct.Guild{} = nostrum_guild) do
    super(Map.from_struct(nostrum_guild))
  end
end
