defmodule AshDiscord.Transformers.EnhanceCommands do
  @moduledoc """
  Enhances Discord commands with domain information and default options.
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Extension
  alias Spark.Dsl.Transformer
  alias AshDiscord.Transformers.AutoDetectOptions
  alias AshDiscord.Transformers.ValidateCommands

  require Logger

  @impl true
  def transform(dsl_state) do
    discord_commands = Extension.get_entities(dsl_state, [:discord])
    discord_options = Extension.get_opt(dsl_state, [:discord], :default_scope, :guild)

    module = Transformer.get_persisted(dsl_state, :module)

    # Enhance commands with domain information and defaults
    enhanced_commands = enhance_commands(discord_commands, discord_options, module)

    # Store commands in the global registry
    dsl_state = Transformer.persist(dsl_state, :discord_commands, enhanced_commands)

    {:ok, dsl_state}
  end

  defp enhance_commands(commands, default_scope, domain) do
    Enum.map(commands, fn command ->
      # Apply domain's default scope if no scope was explicitly set
      scope = if command.scope, do: command.scope, else: default_scope
      %{command | scope: scope, domain: domain}
    end)
  end

  @impl true
  def after?(ValidateCommands), do: true
  def after?(AutoDetectOptions), do: true
  def after?(_), do: false
end
