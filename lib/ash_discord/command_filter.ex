defmodule AshDiscord.CommandFilter do
  @doc """
  Filters a list of commands for a specific guild.

  ## Parameters

  - `commands` - List of command structs to filter
  - `guild` - Guild context (may include permissions, roles, etc.)

  ## Returns

  List of commands that are allowed in the given guild context.
  """
  @callback filter_commands(commands :: list(), guild :: map()) :: list()

  @doc """
  Checks if a specific command is allowed in a guild.

  ## Parameters

  - `command` - The command struct to check
  - `guild` - Guild context (may include permissions, roles, etc.)

  ## Returns

  Boolean indicating whether the command is allowed.
  """
  @callback command_allowed?(command :: map(), guild :: map()) :: boolean()
end
