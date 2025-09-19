defmodule AshDiscord.Checks.AshDiscordInteraction do
  @moduledoc """
  This check is true if the context `private.ash_discord?` is set to true.

  This context will only ever be set in code that is called internally by
  `ash_discord`, allowing you to create a bypass in your policies on your
  user/user_token resources.

  ```elixir
  policies do
    bypass AshDiscordInteraction do
      authorize_if always()
    end
  end
  ```
  """
  use Ash.Policy.SimpleCheck

  alias Ash.Policy.Check
  alias Ash.Policy.SimpleCheck

  @impl Check
  def describe(_) do
    "AshDiscord is performing this interaction"
  end

  @impl SimpleCheck
  def match?(_, %{subject: %{context: %{private: %{ash_discord?: true}}}}, _), do: true
  def match?(_, _, _), do: false
end
