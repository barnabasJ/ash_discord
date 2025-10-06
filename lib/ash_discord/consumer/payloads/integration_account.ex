defmodule AshDiscord.Consumer.Payloads.IntegrationAccount do
  @moduledoc """
  TypedStruct for Discord Integration Account.

  Represents the account information for a guild integration.

  ## References
  - [Discord API - Integration Account Object](https://discord.com/developers/docs/resources/guild#integration-account-object)
  - [Nostrum - Guild.Integration.Account](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.Integration.Account.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :string,
      allow_nil?: false,
      description: "ID of the account"

    field :name, :string,
      allow_nil?: false,
      description: "Name of the account"
  end

  @doc """
  Create an IntegrationAccount TypedStruct from Nostrum Integration Account struct or return existing payload.
  """
  def new(%__MODULE__{} = account), do: {:ok, account}

  def new(%Nostrum.Struct.Guild.Integration.Account{} = account) do
    super(%{
      id: account.id,
      name: account.name
    })
  end
end
