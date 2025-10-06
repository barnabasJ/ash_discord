defmodule AshDiscord.Consumer.Payloads.IntegrationApplication do
  @moduledoc """
  TypedStruct for Discord Integration Application.

  Represents the bot/OAuth2 application for Discord integrations.

  ## References
  - [Discord API - Integration Application Object](https://discord.com/developers/docs/resources/guild#integration-application-object)
  - [Nostrum - Guild.Integration.Application](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Integration.Application.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "ID of the application"

    field :name, :string,
      allow_nil?: false,
      description: "Name of the application"

    field :icon, :string,
      allow_nil?: true,
      description: "Icon hash of the application"

    field :description, :string,
      allow_nil?: false,
      description: "Description of the application"

    field :summary, :string,
      allow_nil?: false,
      description: "Summary of the application"

    field :bot, AshDiscord.Consumer.Payloads.User,
      allow_nil?: true,
      description: "Bot user associated with the application"
  end

  @doc """
  Create an IntegrationApplication TypedStruct from Nostrum Integration Application struct or return existing payload.
  """
  def new(%__MODULE__{} = application), do: {:ok, application}

  def new(%Nostrum.Struct.Guild.Integration.Application{} = application) do
    super(%{
      id: application.id,
      name: application.name,
      icon: application.icon,
      description: application.description,
      summary: application.summary,
      bot: application.bot
    })
  end
end
