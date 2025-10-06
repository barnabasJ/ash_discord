defmodule AshDiscord.Consumer.Payloads.Thread do
  @moduledoc """
  TypedStruct wrapper for Discord Thread data.

  Threads are represented as Channel objects in Discord (types 10, 11, 12).
  This payload type is used specifically for THREAD_CREATE events.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Channel.t()`.

  ## References
  - [Discord API - Thread](https://discord.com/developers/docs/resources/channel#thread-metadata-object)
  - [Discord API - Gateway Thread Create](https://discord.com/developers/docs/topics/gateway-events#thread-create)
  - [Nostrum - Channel](https://hexdocs.pm/nostrum/Nostrum.Struct.Channel.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "The id of the thread"
    field :type, :integer, allow_nil?: false, description: "The type of channel (10, 11, or 12)"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "The id of the guild the thread is located in"

    field :position, :integer, allow_nil?: true, description: "Sorting position of the thread"

    field :permission_overwrites, {:array, :map},
      allow_nil?: true,
      description: "Permission overwrites for members and roles"

    field :name, :string, allow_nil?: true, description: "The name of the thread"
    field :topic, :string, allow_nil?: true, description: "The thread topic"
    field :nsfw, :boolean, allow_nil?: true, description: "Whether the thread is NSFW"

    field :last_message_id, :integer,
      allow_nil?: true,
      description: "The id of the last message sent in this thread"

    field :bitrate, :integer,
      allow_nil?: true,
      description: "The bitrate (in bits) of the voice channel"

    field :user_limit, :integer,
      allow_nil?: true,
      description: "The user limit of the voice channel"

    field :rate_limit_per_user, :integer,
      allow_nil?: true,
      description: "Amount of seconds a user has to wait before sending another message"

    field :recipients, {:array, :map}, allow_nil?: true, description: "The recipients of the DM"
    field :icon, :string, allow_nil?: true, description: "Icon hash"
    field :owner_id, :integer, allow_nil?: true, description: "Id of the thread creator"

    field :application_id, :integer,
      allow_nil?: true,
      description: "Application id of the group DM creator if it is bot-created"

    field :parent_id, :integer,
      allow_nil?: true,
      description: "Id of the parent channel for a thread"

    field :last_pin_timestamp, :utc_datetime,
      allow_nil?: true,
      description: "When the last pinned message was pinned"

    field :rtc_region, :string,
      allow_nil?: true,
      description: "Voice region id for the voice channel"

    field :video_quality_mode, :integer,
      allow_nil?: true,
      description: "The camera video quality mode of the voice channel"

    field :message_count, :integer,
      allow_nil?: true,
      description: "Approximate count of messages in the thread"

    field :member_count, :integer,
      allow_nil?: true,
      description: "Approximate count of users in the thread"

    field :thread_metadata, :map, allow_nil?: true, description: "Thread-specific fields"

    field :member, :map,
      allow_nil?: true,
      description: "Thread member object for the current user"

    field :default_auto_archive_duration, :integer,
      allow_nil?: true,
      description: "Default duration for newly created threads"

    field :permissions, :string,
      allow_nil?: true,
      description: "Computed permissions for the invoking user in the thread"

    field :newly_created, :boolean, description: "Whether the thread is newly created"

    field :available_tags, {:array, :map},
      allow_nil?: true,
      description: "Set of tags that can be used in a forum channel"

    field :applied_tags, {:array, :integer},
      description:
        "The IDs of the set of tags that have been applied to a thread in a forum channel"

    field :default_reaction_emoji, :map,
      allow_nil?: true,
      description: "The emoji to show in the add reaction button on a thread in a forum channel"

    field :default_thread_rate_limit_per_user, :integer,
      allow_nil?: true,
      description: "The initial rate_limit_per_user to set on newly created threads in a channel"

    field :default_sort_order, :integer,
      allow_nil?: true,
      description: "The default sort order type used to order posts in a forum channel"

    field :default_forum_layout, :integer,
      allow_nil?: true,
      description: "The default forum layout view used to display posts in a forum channel"
  end

  @doc """
  Create a Thread TypedStruct from a Nostrum Channel struct.

  Accepts a `Nostrum.Struct.Channel.t()` and creates an AshDiscord Thread TypedStruct.
  Also handles being passed a Thread payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = thread_payload) do
    {:ok, thread_payload}
  end

  def new(%Nostrum.Struct.Channel{} = nostrum_channel) do
    super(Map.from_struct(nostrum_channel))
  end
end
