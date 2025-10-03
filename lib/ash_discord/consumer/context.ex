defmodule AshDiscord.Consumer.Context do
  @moduledoc """
  Discord event context for passing through Ash operations.

  This context carries Discord-specific information like the consumer module,
  guild context, user information, and WebSocket state. It implements the
  `Ash.Scope.ToOpts` protocol to provide actor, tenant, and context information
  to Ash operations.
  """

  defstruct [
    :user,
    :guild_id
  ]

  @type t :: %__MODULE__{
          user: map() | nil,
          guild_id: Nostrum.Snowflake.t() | nil
        }

  defimpl Ash.Scope.ToOpts do
    @doc "Extract the actor (user) from the context"
    def get_actor(%{user: user}) when not is_nil(user), do: {:ok, user}
    def get_actor(_), do: :error

    @doc "Extract the tenant (guild) from the context"
    def get_tenant(%{guild_id: guild_id}) when not is_nil(guild_id),
      do: {:ok, guild_id}

    def get_tenant(_), do: :error

    @doc "Extract shared context information"
    def get_context(_context) do
      :error
    end

    @doc "Tracers are typically configured elsewhere"
    def get_tracer(_), do: :error

    @doc "Authorization should be handled by policies, not scope"
    def get_authorize?(_), do: :error
  end

  @doc """
  Extracts context information from various Discord event payloads.
  """
  def from_payload(_consumer, payload, _ws_state) do
    user =
      cond do
        Map.has_key?(payload, :user) -> payload.user
        Map.has_key?(payload, :author) -> payload.author
        true -> nil
      end

    guild_id = Map.get(payload, :guild_id)

    %__MODULE__{
      user: user,
      guild_id: guild_id
    }
  end
end
