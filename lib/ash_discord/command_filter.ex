defmodule AshDiscord.CommandFilter do
  @moduledoc """
  Behavior for filtering Discord commands before registration or execution.

  Command filters provide runtime control over which commands are available
  in specific guilds or contexts. This enables access control, feature toggles,
  and guild-specific customization.

  ## Behavior Definition

  Modules implementing this behavior must provide two callbacks:

  - `filter_commands/2` - Filters a list of commands for a given guild
  - `command_allowed?/2` - Checks if a specific command is allowed in a guild

  ## Examples

      defmodule MyApp.AdminFilter do
        @behaviour AshDiscord.CommandFilter

        def filter_commands(commands, guild) do
          if has_admin_role?(guild) do
            commands
          else
            Enum.reject(commands, &is_admin_command?/1)
          end
        end

        def command_allowed?(command, guild) do
          if is_admin_command?(command) do
            has_admin_role?(guild)
          else
            true
          end
        end

        defp is_admin_command?(command), do: String.contains?(Atom.to_string(command.name), "admin")
        defp has_admin_role?(guild), do: Map.get(guild, :admin_role, false)
      end

  ## Filter Chains

  Multiple filters can be chained together using `apply_filter_chain/3`:

      filters = [MyApp.AdminFilter, MyApp.FeatureFilter]
      filtered_commands = CommandFilter.apply_filter_chain(commands, guild, filters)

  Filters are applied in sequence, with each filter receiving the result
  of the previous filter.

  ## Integration with Consumer

  Command filters are configured in the consumer DSL and applied during
  command registration and execution:

      defmodule MyApp.Consumer do
        use AshDiscord.Consumer do
          command_filter MyApp.AdminFilter
        end
      end
  """

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

  @doc """
  Applies a chain of filters to a list of commands.

  Filters are applied in sequence, with each filter receiving the result
  of the previous filter. If any filter in the chain is nil or the chain
  is empty, the original commands are returned unchanged.

  ## Parameters

  - `filters` - List of filter modules implementing the CommandFilter behavior
  - `commands` - List of command structs to filter
  - `guild` - Guild context passed to each filter

  ## Returns

  List of commands after applying all filters in the chain.

  ## Examples

      filters = [AdminFilter, FeatureFilter]
      filtered = CommandFilter.apply_filter_chain(filters, commands, guild)
  """
  def apply_filter_chain(nil, _commands, _guild), do: []
  def apply_filter_chain([], commands, _guild), do: commands

  def apply_filter_chain(filters, commands, guild) when is_list(filters) do
    Enum.reduce(filters, commands, fn filter, acc ->
      if filter do
        filter.filter_commands(acc, guild)
      else
        acc
      end
    end)
  end

  @doc """
  Checks if a command is allowed by applying a chain of filters.

  Similar to `apply_filter_chain/3` but for individual command checking.
  All filters in the chain must allow the command for it to be considered
  allowed.

  ## Parameters

  - `filters` - List of filter modules implementing the CommandFilter behavior
  - `command` - The command struct to check
  - `guild` - Guild context passed to each filter

  ## Returns

  Boolean indicating whether the command passes all filters.
  """
  def command_allowed_by_chain?(nil, _command, _guild), do: true
  def command_allowed_by_chain?([], _command, _guild), do: true

  def command_allowed_by_chain?(filters, command, guild) when is_list(filters) do
    Enum.all?(filters, fn filter ->
      if filter do
        filter.command_allowed?(command, guild)
      else
        true
      end
    end)
  end

  @doc """
  Executes a filter function with error handling.

  ## Parameters

  - `filter_module` - The filter module to execute
  - `function_name` - The function to call on the module (:filter_commands or :command_allowed?)
  - `args` - List of arguments to pass to the function

  ## Returns

  The result of the filter function, or a default value if an error occurs.
  """
  def execute_filter(filter_module, function_name, args, default \\ nil) do
    try do
      apply(filter_module, function_name, args)
    rescue
      error ->
        require Logger
        Logger.warning("Filter #{inspect(filter_module)}.#{function_name} failed: #{inspect(error)}")
        default
    end
  end
end