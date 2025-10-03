defmodule AshDiscord.Consumer.Payloads.Channel do
  @moduledoc """
  TypedStruct wrapper for Discord Channel data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Channel.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The id of the channel object"
    field :type, :integer, allow_nil?: false, description: "The type of channel"
    field :guild_id, :integer, description: "The id of the guild the channel is located in"
    field :position, :integer, description: "Sorting position of the channel"

    field :permission_overwrites, {:array, :map},
      description: "Permission overwrites for members and roles"

    field :name, :string, description: "The name of the channel"
    field :topic, :string, description: "The channel topic"
    field :nsfw, :boolean, description: "Whether the channel is NSFW"

    field :last_message_id, :integer,
      description: "The id of the last message sent in this channel"

    field :bitrate, :integer, description: "The bitrate (in bits) of the voice channel"
    field :user_limit, :integer, description: "The user limit of the voice channel"

    field :rate_limit_per_user, :integer,
      description: "Amount of seconds a user has to wait before sending another message"

    field :recipients, {:array, :map}, description: "The recipients of the DM"
    field :icon, :string, description: "Icon hash"
    field :owner_id, :integer, description: "Id of the DM creator"

    field :application_id, :integer,
      description: "Application id of the group DM creator if it is bot-created"

    field :parent_id, :integer, description: "Id of the parent category for a channel"

    field :last_pin_timestamp, :utc_datetime,
      description: "When the last pinned message was pinned"

    field :rtc_region, :string, description: "Voice region id for the voice channel"

    field :video_quality_mode, :integer,
      description: "The camera video quality mode of the voice channel"

    field :message_count, :integer, description: "Approximate count of messages in a thread"
    field :member_count, :integer, description: "Approximate count of users in a thread"
    field :thread_metadata, :map, description: "Thread-specific fields"
    field :member, :map, description: "Thread member object for the current user"

    field :default_auto_archive_duration, :integer,
      description: "Default duration for newly created threads"

    field :permissions, :string,
      description: "Computed permissions for the invoking user in the channel"

    field :newly_created, :boolean, description: "Whether the thread is newly created"

    field :available_tags, {:array, :map},
      description: "Set of tags that can be used in a forum channel"

    field :applied_tags, {:array, :integer},
      description:
        "The IDs of the set of tags that have been applied to a thread in a forum channel"

    field :default_reaction_emoji, :map,
      description: "The emoji to show in the add reaction button on a thread in a forum channel"

    field :default_thread_rate_limit_per_user, :integer,
      description: "The initial rate_limit_per_user to set on newly created threads in a channel"

    field :default_sort_order, :integer,
      description: "The default sort order type used to order posts in a forum channel"

    field :default_forum_layout, :integer,
      description: "The default forum layout view used to display posts in a forum channel"
  end

  @doc """
  Create a Channel TypedStruct from a Nostrum Channel struct.

  Accepts a `Nostrum.Struct.Channel.t()` and creates an AshDiscord Channel TypedStruct.
  """
  def new(%Nostrum.Struct.Channel{} = nostrum_channel) do
    super(Map.from_struct(nostrum_channel))
  end
end
