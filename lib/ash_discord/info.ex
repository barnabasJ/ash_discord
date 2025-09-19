defmodule AshDiscord.Info do
  @moduledoc """
  Introspection for AshDiscord extension.

  Provides functions to retrieve Discord configuration and command definitions
  from modules using the AshDiscord extension.

  The following functions are automatically generated:
  - `discord_commands/1` - Returns all Discord commands
  - `discord_default_scope/1` - Returns the default command scope
  - `discord_error_strategy/1` - Returns the error handling strategy
  - `discord_options/1` - Returns all Discord configuration options
  """

  use Spark.InfoGenerator,
    extension: AshDiscord,
    sections: [:discord]

  @doc """
  Gets a specific Discord command by name.
  """
  def discord_command_by_name(module, name) do
    module
    |> discord_commands()
    |> Enum.find(&(&1.name == name))
  end

  @doc """
  Gets all Discord commands with metadata.

  This includes domain information and resolved scopes.
  """
  def discord_commands(module) do
    commands = discord(module)
    {:ok, default_scope} = discord_default_scope(module)

    Enum.map(commands, fn command ->
      # Apply domain's default scope if no scope was explicitly set
      scope = if command.scope, do: command.scope, else: default_scope
      Map.put(command, :scope, scope) |> Map.put(:domain, module)
    end)
  end
end
