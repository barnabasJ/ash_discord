defmodule AshDiscord.Consumer.Payloads.MessageAttachment do
  @moduledoc """
  TypedStruct wrapper for Discord Message Attachment data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Message.Attachment.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "Attachment id"
    field :filename, :string, allow_nil?: false, description: "Name of attached file"
    field :size, :integer, allow_nil?: false, description: "Size of the file in bytes"
    field :url, :string, allow_nil?: false, description: "Source url of the file"
    field :proxy_url, :string, description: "Proxy url of the file"
    field :height, :integer, description: "Height of the file (if image)"
    field :width, :integer, description: "Width of the file (if image)"
    field :content_type, :string, description: "Media type of the file"
  end

  @doc """
  Create a MessageAttachment TypedStruct from a Nostrum Message.Attachment struct.

  Accepts a `Nostrum.Struct.Message.Attachment.t()` and creates an AshDiscord MessageAttachment TypedStruct.
  Also handles being passed a MessageAttachment payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = attachment_payload) do
    {:ok, attachment_payload}
  end

  def new(%Nostrum.Struct.Message.Attachment{} = nostrum_attachment) do
    super(Map.from_struct(nostrum_attachment))
  end
end
