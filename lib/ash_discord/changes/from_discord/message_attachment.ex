defmodule AshDiscord.Changes.FromDiscord.MessageAttachment do
  @moduledoc """
  Transforms Discord MessageAttachment data into Ash resource attributes.

  This change handles creating/updating MessageAttachment resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.MessageAttachment.t()` with attachment data
  - `:identity` - Map with `%{channel_id: integer, message_id: integer, attachment_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.MessageAttachment
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.MessageAttachment
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case fetch_attachment_from_identity(identity) do
            {:ok, %Payloads.MessageAttachment{} = attachment_data} ->
              transform_message_attachment(changeset, attachment_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.MessageAttachment{} = attachment_data ->
          # Data provided directly, use it
          transform_message_attachment(changeset, attachment_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.MessageAttachment{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_attachment_from_identity(%{
         channel_id: channel_id,
         message_id: message_id,
         attachment_id: attachment_id
       }) do
    # Fetch message from API, which includes attachments
    case Nostrum.Api.Message.get(channel_id, message_id) do
      {:ok, message} ->
        case Enum.find(message.attachments, fn att -> att.id == attachment_id end) do
          nil ->
            {:error,
             "Attachment #{attachment_id} not found in message #{message_id} (channel #{channel_id})"}

          attachment ->
            Payloads.MessageAttachment.new(attachment)
        end

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_attachment_from_identity(_),
    do:
      {:error,
       "Identity must be a map with channel_id, message_id, and attachment_id for API fallback"}

  defp transform_message_attachment(changeset, attachment_data) do
    # Infer content type from filename (Nostrum doesn't provide content_type)
    content_type = infer_content_type(attachment_data.filename)

    changeset
    |> maybe_set_attribute(:discord_id, attachment_data.id)
    |> maybe_set_attribute(:filename, attachment_data.filename)
    |> maybe_set_attribute(:size, attachment_data.size)
    |> maybe_set_attribute(:url, attachment_data.url)
    |> maybe_set_attribute(:proxy_url, attachment_data.proxy_url)
    |> maybe_set_attribute(:height, attachment_data.height)
    |> maybe_set_attribute(:width, attachment_data.width)
    |> maybe_set_attribute(:content_type, content_type)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  # Infer content type from filename extension
  defp infer_content_type(nil), do: nil

  defp infer_content_type(filename) when is_binary(filename) do
    case String.downcase(Path.extname(filename)) do
      ".pdf" -> "application/pdf"
      ".png" -> "image/png"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      ".txt" -> "text/plain"
      ".json" -> "application/json"
      ".zip" -> "application/zip"
      ".mp4" -> "video/mp4"
      ".mov" -> "video/quicktime"
      ".avi" -> "video/x-msvideo"
      ".mkv" -> "video/x-matroska"
      ".webm" -> "video/webm"
      ".mp3" -> "audio/mpeg"
      ".wav" -> "audio/wav"
      ".ogg" -> "audio/ogg"
      ".flac" -> "audio/flac"
      _ -> "application/octet-stream"
    end
  end

  defp infer_content_type(_), do: nil
end
